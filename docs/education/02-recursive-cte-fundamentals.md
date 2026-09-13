# Lesson 2: Build a recursive CTE mental model

## Goal

Understand the anchor member, recursive member, working rows, termination, and state carried through a traversal.

## The two-part query

A recursive CTE has a non-recursive anchor and a recursive member joined by `UNION ALL` or `UNION`:

```sql
WITH RECURSIVE walk AS (
    -- 1. Anchor: create the starting rows.
    SELECT ...

    UNION ALL

    -- 2. Recursive member: derive the next rows from walk.
    SELECT ...
    FROM walk
    JOIN ...
)
-- 3. Consume all rows produced by the CTE.
SELECT ...
FROM walk;
```

PostgreSQL evaluates this iteratively even though the SQL is written recursively.

```text
iteration 0: anchor produces                 storefront
iteration 1: follow its edges                api
iteration 2: follow api's edges              auth, catalog, orders, ...
iteration 3: follow those edges              postgres, inventory, ...
iteration N: no rows remain                  stop
```

## State travels with each row

The walk query carries more than the current node:

```text
+-------------+-------+--------------------------+-----------------------+
| current     | depth | path_ids                 | path_names            |
+-------------+-------+--------------------------+-----------------------+
| storefront  |   0   | {1}                      | {storefront}          |
| api         |   1   | {1,2}                    | {storefront,api}      |
| catalog     |   2   | {1,2,4}                  | {storefront,api,...}  |
+-------------+-------+--------------------------+-----------------------+
```

Each recursive step appends state:

```sql
w.depth + 1,
w.path_ids || child.id,
w.path_names || child.name
```

This pattern is broadly useful. A row can carry total cost, visited edges, root ID, lineage, or any other value needed by later steps.

## Termination and cycles

A tree eventually runs out of children. A graph may cycle forever:

```text
pricing --> legacy_tax_rules
   ^              |
   +--------------+
```

The lab permits only simple paths—paths that do not repeat a vertex:

```sql
WHERE NOT (child.id = ANY(w.path_ids))
```

For production traversal, also consider a depth bound:

```sql
WHERE w.depth < %(max_depth)s
  AND NOT (child.id = ANY(w.path_ids))
```

The cycle check protects correctness; the depth limit places a predictable ceiling on work.

## `UNION ALL` versus `UNION`

`UNION ALL` preserves every generated row. That matters when two different paths reach the same node:

```text
api -> catalog -> postgres
api -> orders  -> postgres
```

These rows have the same destination but different paths. We want both.

`UNION` removes rows that are identical across every selected CTE column. It can sometimes stop cycles when the CTE contains only the current node, but it is not a general cycle solution once depth or path is included—those values make each loop-generated row different.

## Output order is separate from evaluation

Do not treat PostgreSQL's internal recursive evaluation order as part of your result contract. Sort the final rows explicitly:

```sql
ORDER BY depth, path;
```

This controls presentation. It does not change which rows recursion explores.

## Read the working example

Open `sql/queries/01_walk.sql` and identify:

1. The anchor row.
2. The recursive self-reference to `walk`.
3. The edge and child-node joins.
4. The state appended on each step.
5. The cycle predicate.
6. The final ordering.

Then run:

```sh
python -m scripts.walk_graph --start api --max-depth 8
```

## Checkpoint

You are ready for Lesson 3 when you can describe exactly why `postgres` appears several times in the walk output while the pricing cycle still terminates.
