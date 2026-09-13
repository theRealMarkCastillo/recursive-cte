# Recursive CTE graph lab for PostgreSQL

A runnable lab for learning how PostgreSQL can store a directed graph in ordinary tables and traverse it with `WITH RECURSIVE`.

The project includes a PostgreSQL 16 container, a seeded service-dependency graph, four parameterized SQL queries, Python command-line clients, a guided course, and an operations runbook.

## System map

```text
  Python commands                    Docker Compose

  scripts/walk_graph.py ------+
  scripts/find_paths.py ------+-- psycopg --> 127.0.0.1:55450
  scripts/shortest_path.py ----+                         |
  scripts/dependency_... ------+                         v
                                           +------------------+
                                           | PostgreSQL :5432 |
                                           |                  |
                                           | graph_nodes      |
                                           | graph_edges      |
                                           +------------------+
```

The host port is `55450`, selected because it did not conflict with the other Docker projects running when this lab was created. PostgreSQL keeps its normal port, `5432`, inside the container.

## Sample graph

An arrow means “the node on the left uses the node on the right.”

```text
storefront --calls--> api
                       |
                       +--calls------> auth
                       |
                       +--calls------> catalog --reads_from--> postgres
                       |
                       +--calls------> orders --reads_from---> postgres
                       |                 |
                       |                 +--calls--> inventory --reads_from--> postgres
                       |                 `--calls--> payments  --reads_from--> postgres
                       |
                       +--calls------> pricing --reads_from---> postgres
                       |                 |
                       |                 `--imports--> legacy_tax_rules --depends_on--> pricing
                       |
                       `--reads_from-> redis

worker    ----consumes----> queue
    `-----writes_to-------> postgres

reporting ----consumes----> queue
    `-----reads_from------> postgres
```

`pricing` and `legacy_tax_rules` intentionally form a cycle. The traversal queries remember the current path and refuse to revisit a node already in it.

## How recursive evaluation works

```text
                  first iteration
                 +----------------+
                 |                v
anchor query --> working rows --> recursive query
                    ^                    |
                    |   new rows         |
                    +--------------------+
                    |
                    +-- no new rows --> final SELECT
```

In this lab, each recursive row carries:

```text
current node + depth + visited node IDs + display path
```

The visited-ID array is the cycle guard:

```sql
WHERE NOT (child.id = ANY(w.path_ids))
```

## Why use this approach?

Recursive CTEs are a strong fit when PostgreSQL is already the system of record, graph updates must share transactions with relational data, and traversals are shallow or firmly bounded. You keep one data platform, ordinary SQL joins, foreign keys, and existing PostgreSQL operations.

The tradeoff is that path handling is manual and highly connected graphs can generate very large intermediate results. If deep graph patterns or algorithms such as weighted shortest paths, PageRank, or community detection dominate the workload, consider PostgreSQL extensions such as Apache AGE or pgRouting, or a graph-native database.

See [Choosing PostgreSQL or a graph database](docs/education/06-choosing-a-graph-approach.md) for relational alternatives, PostgreSQL extensions, graph databases, a comparison table, and a decision tree.

## Quick start

From the repository root:

```sh
cp .env.example .env       # optional; defaults work without this file
docker compose up -d --wait

python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements.txt
```

Run the examples:

```sh
python -m scripts.walk_graph --start storefront
python -m scripts.find_paths storefront postgres
python -m scripts.shortest_path storefront postgres
python -m scripts.dependency_summary --start storefront
```

Or use the convenience targets:

```sh
make up
make walk
make paths
make shortest
make summary
```

The development defaults are:

```text
host:     127.0.0.1
port:     55450
database: graphdb
user:     graph_user
password: graph_password
```

If you customize `.env`, export it before running Python so Docker Compose and psycopg use the same settings:

```sh
set -a
. ./.env
set +a
```

## Learning path

1. [Graph modeling in PostgreSQL](docs/education/01-graph-model.md)
2. [Recursive CTE mental model](docs/education/02-recursive-cte-fundamentals.md)
3. [Traversal and path queries](docs/education/03-path-queries.md)
4. [Safety, performance, and PostgreSQL features](docs/education/04-safety-and-performance.md)
5. [Exercises and solutions](docs/education/05-exercises.md)
6. [Choosing PostgreSQL or a graph database](docs/education/06-choosing-a-graph-approach.md)

For normal operation and troubleshooting, use the [runbook](docs/RUNBOOK.md).

## Project layout

```text
recursive-cte/
|-- docker-compose.yml
|-- Makefile
|-- requirements.txt
|-- scripts/
|   |-- common.py
|   |-- walk_graph.py
|   |-- find_paths.py
|   |-- shortest_path.py
|   `-- dependency_summary.py
|-- sql/
|   |-- 01-schema.sql
|   |-- 02-seed.sql
|   `-- queries/
|       |-- 01_walk.sql
|       |-- 02_find_paths.sql
|       |-- 03_shortest_path.sql
|       `-- 04_dependency_summary.sql
`-- docs/
    |-- RUNBOOK.md
    `-- education/
        `-- 01-... through 06-...
```

The query files use psycopg named parameters such as `%(start)s`. The schema and seed files are mounted into PostgreSQL's initialization directory and run only when the Docker volume is first created.
