# Weighted routes

## Question

Why can the shortest-distance path differ from the path with the fewest edges?

```text
Depot --2 km--> A --8 km----------------> Store
                 `--2 km--> C --3 km----> Store

Depot --3 km--> B --9 km----------------> Store
                 `--3 km--> C --3 km----> Store
```

The key candidate routes are:

```text
Depot -> A -> Store       2 hops, 10 km
Depot -> A -> C -> Store  3 hops,  7 km
Depot -> B -> C -> Store  3 hops,  9 km
Depot -> B -> Store       2 hops, 12 km
```

## Run

```sh
make demo-routes
```

The fewest-hop answer is 10 km; the shortest-distance answer is 7 km.

## Read the SQL

- `queries/01_all_paths.sql` carries distance and travel time through every simple path.
- `queries/02_shortest_distance.sql` sorts candidates by accumulated distance.
- `queries/03_fewest_hops.sql` sorts the same graph by depth first.

## Important limitation

These teaching queries enumerate simple paths and sort completed candidates. They are not Dijkstra or A*. Work grows rapidly on dense graphs. Use a strict depth bound; for serious network routing, evaluate pgRouting or another specialized engine.

## Try it

1. Sort by `total_minutes` instead of distance.
2. Add a toll cost and optimize a combined score.
3. Add reverse edges and observe how the candidate count grows.
4. Compare this SQL with pgRouting's Dijkstra implementation.
