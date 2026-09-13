# Lesson 4: Safety, performance, and PostgreSQL features

## Goal

Know the practical limits of recursive traversal and the safeguards to apply before using it on larger data.

## The main risk: path explosion

If each node has several outgoing edges, the number of paths can grow much faster than the number of nodes.

```text
depth          possible rows at branching factor 4
-----          -----------------------------------
0              1
1              4
2              16
3              64
4              256
8              65,536
```

Cycle prevention avoids revisiting a node within one path, but it does not prevent many distinct paths from reaching the same destination.

## Use layered safeguards

For exploratory queries, combine:

```text
cycle guard + maximum depth + narrow edge filters + statement timeout
```

Examples:

```sql
-- Per-path cycle guard
AND NOT (child.id = ANY(p.path_ids))

-- Depth guard
AND p.depth < %(max_depth)s

-- Follow only one relationship family
AND e.relationship IN ('calls', 'reads_from')
```

Set a session-local timeout while experimenting in `psql`:

```sql
SET statement_timeout = '5s';
```

## Index the expansion join

The hot operation is usually finding the next edges. Verify that the expansion column is indexed:

```text
outgoing traversal   graph_edges.from_node_id
incoming traversal   graph_edges.to_node_id
```

This lab has both. Additional relationship filters may benefit from composite indexes on real data, for example `(from_node_id, relationship, to_node_id)`.

## Inspect the plan

Use `EXPLAIN (ANALYZE, BUFFERS)` only when it is safe to actually execute the query:

```sql
EXPLAIN (ANALYZE, BUFFERS)
WITH RECURSIVE ...
SELECT ...;
```

Look for:

- A `Recursive Union` node.
- How many rows each recursive loop emits.
- The loop count.
- Index scans or bitmap scans on `graph_edges`.
- Large differences between estimated and actual row counts.

Use plain `EXPLAIN` first if the query might be expensive.

## PostgreSQL `SEARCH` and `CYCLE`

PostgreSQL 16 supports SQL-standard clauses that can calculate traversal ordering and cycle information:

```sql
WITH RECURSIVE walk(id, name) AS (
    SELECT id, name
    FROM graph_nodes
    WHERE name = 'api'

    UNION ALL

    SELECT child.id, child.name
    FROM walk
    JOIN graph_edges AS e ON e.from_node_id = walk.id
    JOIN graph_nodes AS child ON child.id = e.to_node_id
)
SEARCH DEPTH FIRST BY id SET order_path
CYCLE id SET is_cycle USING cycle_path
SELECT id, name, is_cycle, order_path
FROM walk
WHERE NOT is_cycle
ORDER BY order_path;
```

The explicit arrays used elsewhere in this lab are still worth learning: they make path state visible and allow custom rules such as preventing repeated edges rather than repeated nodes.

## Know when to switch tools

Recursive SQL is a good fit for:

- Hierarchies and bills of materials.
- Bounded dependency traversal.
- Authorization inheritance.
- Small graph exploration close to relational data.

Consider a graph engine, extension, or application-side algorithm when you need frequent deep traversals over a large, highly connected graph; many weighted shortest paths; centrality; community detection; or graph-specific indexing and query languages.

Lesson 6 provides a detailed comparison of these choices.

## Production checklist

- Define edge direction and path semantics.
- Ensure expansion columns are indexed.
- Add cycle handling even if cycles “should not exist.”
- Add a depth or cost boundary.
- Apply a statement timeout for user-controlled traversal.
- Filter by tenant or authorization scope inside both anchor and recursion.
- Measure row growth with representative data.
- Return bounded results to clients.
- Avoid interpolating SQL; bind node names and limits as parameters.
