# Bill of materials

## Question

How many of each component are needed to build one bicycle?

```text
bicycle
|-- 2 x wheel
|   |-- 36 x spoke       => 72 spokes per bicycle
|   |-- 1 x rim
|   |-- 1 x hub
|   |-- 1 x tire
|   `-- 1 x tube
|-- 1 x frame -- 4 x bolt
|-- 1 x seat --- 2 x bolt
`-- 1 x handlebar
    |-- 2 x grip
    `-- 2 x bolt         => 8 bolts in total
```

## Model

`bom.components` connects a parent assembly to a child part and stores the quantity needed per parent. The recursive row carries the quantity required along its path:

```sql
exploded.required_quantity * component.quantity
```

## Run

```sh
make demo-bom
```

Expected totals include `72` spokes, `2` wheels, and `8` bolts. Bolts demonstrate why aggregation happens after recursion: three different assembly paths contribute to the total.

## Read the SQL

- `queries/01_explode.sql` preserves every component path.
- `queries/02_totals.sql` groups the recursive output by component.

## Try it

1. Run the demo with `--part wheel`.
2. Add pedals that each require two bearings.
3. Change bicycle quantity from one to ten by changing the anchor multiplier.
4. Decide whether assemblies such as `wheel` should appear in a purchasing report or only leaf components should.
