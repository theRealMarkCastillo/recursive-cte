# Lesson 7: Walk through practical use cases

## Goal

See how the same recursive CTE structure solves six different problems by changing edge direction and the state carried in each row.

## Prepare the lab

```sh
make up
make install
make load-examples
```

The examples live in separate schemas, so table names and domain rules remain clear:

```text
org          organization hierarchy
bom          products and component quantities
rbac         users, roles, inheritance, and permissions
lineage      data assets and dependencies
discussion   comments and parent relationships
routes       locations and weighted connections
```

Each `make demo-*` command is safe to repeat because its seed is idempotent.

## 1. Organization: change traversal direction

```sh
make demo-org
```

First inspect `examples/org_chart/queries/01_reports.sql`. Its recursive join finds rows whose `manager_id` points to the current employee. Then compare `02_management_chain.sql`, which follows the current employee's `manager_id` upward.

```text
downward question                 upward question
-----------------                 ---------------
Who reports to Alice?             Who manages Erin?
current.id -> child.manager_id    current.manager_id -> manager.id
```

Checkpoint: explain why the same table needs two different join directions.

## 2. Bill of materials: carry computed state

```sh
make demo-bom
```

The recursive member does more than append a path:

```sql
exploded.required_quantity * component.quantity
```

Two wheels times 36 spokes produces 72 spokes. Bolts arrive through three paths and are summed after recursion.

Checkpoint: identify which values belong to one path and which values are aggregated across paths.

## 3. Permissions: distinguish paths from effective results

```sh
make demo-rbac
```

Alice reaches `viewer` twice:

```text
admin -> editor  -> viewer
admin -> auditor -> viewer
```

Both paths are legitimate traversal results. Effective permissions are a set, so the final query uses `DISTINCT`.

Checkpoint: decide where duplicates carry meaning and where they should be removed.

## 4. Data lineage: ask upstream and downstream questions

```sh
make demo-lineage
```

Upstream lineage answers “what produced this asset?” Downstream impact answers “what consumes this asset?” Both use `lineage.dependencies`; only the expansion direction changes.

Checkpoint: write the two edge joins beside each other and identify the swapped columns.

## 5. Discussion threads: separate traversal from presentation

```sh
make demo-discussion
```

Depth controls indentation, while a recursively accumulated timestamp array gives a depth-first display order. The database stores flat rows; hierarchy is reconstructed for the result.

Checkpoint: explain why `ORDER BY depth` alone would group levels instead of keeping replies under their parents.

## 6. Weighted routes: define “shortest” precisely

```sh
make demo-routes
```

The fewest-hop route is not the shortest-distance route:

```text
fewest hops        Depot -> A -> Store       2 hops, 10 km
shortest distance  Depot -> A -> C -> Store  3 hops,  7 km
```

The recursion carries `total_distance_km` and `total_minutes`. The final ordering defines the winner.

Checkpoint: explain why enumerating all simple paths is educational but not equivalent to Dijkstra's early-termination behavior.

## Compare all six

```text
Use case            Anchor              Recursive state added
--------            ------              ---------------------
organization        selected employee   depth + employee path
BOM                 selected product    multiplied quantity
permissions         user's direct role  inherited role path
lineage             selected asset      dependency path
discussion          root comment        depth + chronological path
routes              source location     distance + time + path
```

The reusable recipe is:

```text
1. Define the anchor precisely.
2. Choose edge direction from the business question.
3. Carry every value needed by later recursion or final output.
4. Prevent cycles according to node or edge semantics.
5. Bound the work by depth, cost, relationship type, or scope.
6. Aggregate or rank only after deciding what one recursive row represents.
```

## Verify your environment

Run the full automated suite after experimenting:

```sh
make test
```

The practical fixtures are reset only inside the test transaction and rolled back afterward, so your example data is preserved.

To restore an example's canonical rows without deleting the database, rerun its demo or `make load-examples`. Extra rows you add are intentionally preserved. To erase everything and recreate the core database, use the destructive reset procedure in `docs/RUNBOOK.md`.
