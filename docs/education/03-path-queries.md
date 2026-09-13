# Lesson 3: Traversal and path queries

## Goal

Distinguish graph questions that sound similar but require different result shapes.

## Four questions in this lab

```text
Question                                Query/script
--------                                ------------
Show every reachable path               01_walk.sql / walk_graph.py
Show paths from A to B                   02_find_paths.sql / find_paths.py
Choose a fewest-hop path                 03_shortest_path.sql / shortest_path.py
Summarize reachability by destination    04_dependency_summary.sql
```

## Reachability versus paths

“Can A reach B?” needs only a yes/no answer. “How can A reach B?” needs the path state. “Which nodes can A reach?” may want each node only once, or once per route.

This lab intentionally keeps one row per simple path. That is why `postgres` appears five times when walking from `storefront`.

To return each reachable node once, aggregate after recursion:

```sql
SELECT id, name, MIN(depth) AS min_hops
FROM walk
GROUP BY id, name
ORDER BY min_hops, name;
```

## Find all simple paths

The path query starts at `source`, recursively expands outgoing edges, and filters the completed rows to `target`:

```text
source
  |
  +--> candidate path --> target  keep
  |
  +--> candidate path --> other   continue if safe
  |
  `--> repeated node              discard
```

Run it with:

```sh
python -m scripts.find_paths storefront postgres --max-depth 8
```

The seeded graph produces five routes. The result preserves both node names and relationships so you can inspect how each route was formed.

## Shortest by hop count

The shortest-path query generates simple candidate paths, then chooses one explicitly:

```sql
ORDER BY depth, path
LIMIT 1;
```

`depth` is the hop count, so this is an unweighted shortest path. `path` provides a deterministic tie-breaker when several routes have equal length.

```sh
python -m scripts.shortest_path storefront postgres
```

Important limitation: enumerating all simple paths can grow exponentially. This teaching technique is suitable for small or tightly bounded graphs, not arbitrary large shortest-path workloads.

## Weighted paths

The schema includes `graph_edges.weight`, but the shortest-path example does not use it. To calculate candidate path cost, add state such as:

```sql
0::BIGINT AS total_weight
```

and update it recursively:

```sql
p.total_weight + e.weight
```

Then sort completed candidates by `total_weight`. This still enumerates candidate paths, so a depth bound remains important. At large scale, use a dedicated shortest-path algorithm or graph extension instead of assuming a recursive CTE is Dijkstra's algorithm.

## Reverse traversal

To answer “what would be affected if Postgres were unavailable?”, walk incoming edges:

```sql
JOIN graph_edges AS e ON e.to_node_id = current.id
JOIN graph_nodes AS parent ON parent.id = e.from_node_id
```

Starting from `postgres`, this finds direct consumers first, then their consumers.

```text
postgres
   ^-- catalog <-- api <-- storefront
   ^-- orders  <-- api <-- storefront
   ^-- pricing <-- api <-- storefront
   |       ^-- legacy_tax_rules
   ^-- worker
   `-- reporting
```

## Stop expanding completed paths

When only paths to one target matter, the recursive member can avoid expanding a row after it reaches that target. Resolve the target ID and add:

```sql
AND p.current_id <> target_id
```

This optimization is useful if the target itself has many outgoing edges. It does not eliminate path explosion before the target.

## Checkpoint

You are ready for Lesson 4 when you can state whether a requested “shortest path” means fewest edges or lowest total weight, and why that distinction changes the query.
