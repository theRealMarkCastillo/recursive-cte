# Lesson 5: Exercises and solutions

Work through the exercises in order. Each one changes only a copy of an existing query or adds temporary data; the solutions follow after the divider.

## Exercise 1: Change the root

Run the walk from `orders`, then predict the rows before looking at the output.

```sh
python -m scripts.walk_graph --start orders --max-depth 8
```

Questions:

1. Which nodes occur at depth 1?
2. How many paths reach `postgres`?
3. Why does `api` not appear?

## Exercise 2: Observe the cycle guard

Run the walk from `pricing`:

```sh
python -m scripts.walk_graph --start pricing --max-depth 8
```

Trace the path array when the traversal reaches `legacy_tax_rules`. Explain why its edge back to `pricing` does not generate a row.

## Exercise 3: Apply a depth bound

Run:

```sh
python -m scripts.find_paths storefront postgres --max-depth 3
```

Compare it with `--max-depth 4`. Which routes appear only at depth 4?

## Exercise 4: Reverse the graph

Copy `sql/queries/01_walk.sql` to a scratch file and reverse the two expansion joins so traversal follows incoming edges. Start from `postgres` and answer: which services are transitively affected by a PostgreSQL outage?

## Exercise 5: Lowest-weight path

Copy `sql/queries/03_shortest_path.sql`. Add a `total_weight` column to both sides of the recursive CTE, initialize it to zero, and add each edge's weight during recursion. Sort by weight before depth.

Does the lowest-weight route from `storefront` to `postgres` differ from the fewest-hop route with the current seed data?

## Exercise 6: Add a node and edge

In `psql`, add an object-storage dependency for reporting:

```sql
INSERT INTO graph_nodes (name, kind)
VALUES ('object_storage', 'infrastructure');

INSERT INTO graph_edges (from_node_id, to_node_id, relationship, weight)
SELECT source.id, target.id, 'writes_to', 1
FROM graph_nodes AS source
CROSS JOIN graph_nodes AS target
WHERE source.name = 'reporting'
  AND target.name = 'object_storage';
```

Walk from `reporting` and verify the new node appears.

---

# Solutions

## Solution 1

At depth 1, `orders` reaches `inventory`, `payments`, and `postgres`. Three simple paths reach `postgres`: the direct path and one through each of the other two services. `api` does not appear because edges point from consumers to dependencies; `orders -> api` is not an edge.

## Solution 2

At `legacy_tax_rules`, `path_ids` already contains the ID for `pricing`. The predicate below rejects the edge back to it:

```sql
NOT (child.id = ANY(w.path_ids))
```

## Solution 3

At maximum depth 3, the direct routes through `catalog`, `orders`, and `pricing` appear. Depth 4 adds the routes through `orders -> inventory` and `orders -> payments`.

## Solution 4

Replace the outgoing expansion:

```sql
JOIN graph_edges AS e ON e.from_node_id = w.id
JOIN graph_nodes AS child ON child.id = e.to_node_id
```

with incoming expansion:

```sql
JOIN graph_edges AS e ON e.to_node_id = w.id
JOIN graph_nodes AS child ON child.id = e.from_node_id
```

The affected set includes `catalog`, `orders`, `payments`, `inventory`, `pricing`, `legacy_tax_rules`, `worker`, `reporting`, `api`, and `storefront`. Some may appear through multiple paths.

## Solution 5

Add to the anchor:

```sql
0::BIGINT AS total_weight
```

Add to the recursive member in the same column position:

```sql
p.total_weight + e.weight
```

Then use:

```sql
ORDER BY total_weight, depth, path
LIMIT 1;
```

With the seed data, the lowest total weight is 3 and several three-hop routes tie. The existing path-name tie-breaker selects the route through `catalog`.

## Solution 6

The reporting walk should include `reporting` at depth 0 and `object_storage` at depth 1. To restore the original seeded state, follow the reset procedure in `docs/RUNBOOK.md`; it deletes the lab's database volume.
