# Discussion threads

## Question

How can flat comment rows be rendered as a nested conversation?

```text
Alice: How should I prevent cycles?
|-- Bob: Carry visited node IDs in an array.
|   `-- Deepa: Why use UNION ALL?
|       `-- Erin: It preserves distinct paths to the same node.
`-- Carol: Also add a maximum depth.
```

## Model

Each comment has an optional `parent_id`. Roots have no parent. The recursive query carries depth for indentation, IDs for cycle protection, and timestamps for depth-first sibling ordering.

## Run

```sh
make demo-discussion
```

The second query reconstructs the conversation path from `reply-erin` to the root.

## Read the SQL

- `queries/01_thread.sql` walks children and orders by the recursive sort path.
- `queries/02_ancestors.sql` follows parents back to the root.

## Try it

1. Add a second reply beneath Carol.
2. Change timestamps and observe sibling ordering.
3. Add pagination requirements and consider why paginating a nested tree is harder than paginating flat rows.
4. Add a moderation flag and decide whether hidden comments should hide or re-parent their visible descendants.
