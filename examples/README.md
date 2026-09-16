# Practical recursive CTE examples

These modules move from a tree to DAGs and then weighted paths. Each one has an isolated PostgreSQL schema, idempotent seed data, parameterized recursive queries, a Python demo, expected results, and exercises.

## Recommended order

```text
1. org_chart          tree traversal in both directions
        |
2. bill_of_materials recursive multiplication and aggregation
        |
3. permissions        DAG traversal and deduplication
        |
4. data_lineage       upstream and downstream impact
        |
5. discussion_threads depth-first presentation of a tree
        |
6. weighted_routes    accumulated cost and algorithm limits
```

## Run everything

Start PostgreSQL and install Python dependencies as described in the root README, then run:

```sh
make demos
```

Each demo creates and idempotently seeds its own schema before querying it. To load all schemas without running demos:

```sh
make load-examples
```

Run modules individually:

```sh
make demo-org
make demo-bom
make demo-rbac
make demo-lineage
make demo-discussion
make demo-routes
```

## What changes between examples?

```text
Example             Shape       State carried through recursion
-------             -----       -------------------------------
organization        tree        depth, employee path
bill of materials   DAG         depth, path, multiplied quantity
permissions         DAG         depth, visited roles, role path
data lineage        DAG         depth, visited assets, asset path
discussion          tree        depth, path, chronological sort path
weighted routes     graph       depth, visited locations, cost, time
```

## Module guides

- [Organization chart](org_chart/README.md)
- [Bill of materials](bill_of_materials/README.md)
- [Permission inheritance](permissions/README.md)
- [Data lineage](data_lineage/README.md)
- [Discussion threads](discussion_threads/README.md)
- [Weighted routes](weighted_routes/README.md)

For a lesson that walks through all six and gives comparison questions, read [Practical recursive CTE use cases](../docs/education/07-practical-use-cases.md).

## Query files and parameters

The query files use psycopg named parameters such as `%(max_depth)s`. Run them through their demo programs. If you paste one into `psql`, replace each placeholder with a literal or a `psql` variable first.

Every recursive query includes both a path-based cycle guard and a maximum depth. The weighted-route queries intentionally enumerate simple candidate paths for teaching; they are not implementations of Dijkstra or A*.

The automated tests create canonical fixtures inside a transaction and roll it back afterward. Running `make test` will not erase or replace rows you added during the exercises.
