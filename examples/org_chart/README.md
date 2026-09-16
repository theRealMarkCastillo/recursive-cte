# Organization chart

## Question

Who reports directly or indirectly to a manager, and what is an employee's chain to the CEO?

```text
Alice (CEO)
|-- Bob (CTO)
|   `-- Deepa (Engineering Manager)
|       |-- Erin (Software Engineer)
|       `-- Faisal (Software Engineer)
`-- Carol (CFO)
    `-- Grace (Accountant)
```

## Model

`org.employees.manager_id` is a self-referencing foreign key. Following `employee.manager_id = current.id` walks downward. Following `manager.id = current.manager_id` walks upward.

## Run

```sh
make demo-org
```

Or customize both ends:

```sh
python -m examples.org_chart.demo --manager Bob --employee Faisal
```

Expected facts:

- Alice's tree contains seven employees including Alice.
- Erin's management chain is `Alice -> Bob -> Deepa -> Erin`.
- The final query orders by the ID path to produce a depth-first tree.

## Read the SQL

- `queries/01_reports.sql` follows incoming reports recursively.
- `queries/02_management_chain.sql` follows manager pointers toward the root.

Focus on how changing only the join direction reverses the traversal.

## Try it

1. Start the report query at `Deepa`.
2. Find Grace's management chain.
3. Add a second team under Bob and predict the depth-first output.
4. Consider how you would reject a manager assignment that creates a multi-row cycle; a row-level check constraint cannot detect that by itself.
