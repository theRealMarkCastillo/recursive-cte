# Lesson 1: Model a graph in PostgreSQL

## Goal

Understand how vertices and directed edges map to relational tables, and how edge direction changes the meaning of a traversal.

## From graph terms to tables

This lab uses the adjacency-list model:

```text
Graph concept       PostgreSQL representation
-------------       -------------------------
vertex/node         one row in graph_nodes
directed edge       one row in graph_edges
node property       a column on graph_nodes
edge property       a column on graph_edges
outgoing neighbors  edges matching from_node_id
incoming neighbors  edges matching to_node_id
```

The schema is defined in `sql/01-schema.sql`:

```sql
CREATE TABLE graph_nodes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    kind TEXT NOT NULL
);

CREATE TABLE graph_edges (
    from_node_id BIGINT NOT NULL REFERENCES graph_nodes(id),
    to_node_id BIGINT NOT NULL REFERENCES graph_nodes(id),
    relationship TEXT NOT NULL,
    weight INTEGER NOT NULL,
    PRIMARY KEY (from_node_id, to_node_id)
);
```

The foreign keys keep edges from pointing at nonexistent nodes. `ON DELETE CASCADE` in the actual schema removes attached edges if a node is deleted.

## Edge direction

Direction is a modeling decision. In this lab:

```text
source ----relationship----> target
  api --------calls--------> auth
```

Following `from_node_id -> to_node_id` answers “what does this component depend on?” Reversing the join answers “what depends on this component?”

Outgoing traversal:

```sql
JOIN graph_edges AS e ON e.from_node_id = current_node.id
JOIN graph_nodes AS next ON next.id = e.to_node_id
```

Incoming traversal:

```sql
JOIN graph_edges AS e ON e.to_node_id = current_node.id
JOIN graph_nodes AS next ON next.id = e.from_node_id
```

## Why this index layout works

The primary key on `(from_node_id, to_node_id)` creates a B-tree index whose leading column is `from_node_id`. That supports outgoing-edge lookups. The schema adds a separate index on `to_node_id` for reverse traversal.

```text
query direction        useful index
---------------        ------------
from -> to             (from_node_id, to_node_id) primary key
to -> from             (to_node_id)
```

## Inspect the seed graph

Open `psql`:

```sh
docker compose exec postgres psql -U graph_user -d graphdb
```

Then list readable edges:

```sql
SELECT
    source.name AS source,
    e.relationship,
    target.name AS target,
    e.weight
FROM graph_edges AS e
JOIN graph_nodes AS source ON source.id = e.from_node_id
JOIN graph_nodes AS target ON target.id = e.to_node_id
ORDER BY source.name, target.name;
```

## Design questions for a real graph

Before writing recursion, decide:

- Whether edges are directed, undirected, or a mixture.
- Whether two nodes may have several differently typed edges between them.
- Which node and edge properties must be searchable.
- Whether a “path” may revisit a node or edge.
- Whether cost means hops, a stored weight, elapsed time, or something else.

If multiple relationship types between the same pair are valid, give `graph_edges` its own identity primary key and add an index such as `(from_node_id, to_node_id)` instead of using that pair as the primary key.

## Checkpoint

You are ready for Lesson 2 when you can explain why walking from `api` reaches `postgres`, but walking from `postgres` along outgoing edges reaches nothing.
