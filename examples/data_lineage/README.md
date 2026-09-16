# Data lineage

## Questions

What feeds a dashboard, and what breaks when a source changes?

```text
raw_orders --> stg_orders --> fct_orders ------> dashboard_revenue
                                  |
                                  `------------> customer_metrics
                                                     |
raw_customers -> stg_customers -> dim_customer ------+--> dashboard_retention
```

The edge is stored as `downstream depends on upstream`.

## Run

```sh
make demo-lineage
```

The demo walks upstream from `dashboard_revenue` and downstream from `raw_orders`.

## Read the SQL

- `queries/01_upstream.sql` joins from a downstream asset to its sources.
- `queries/02_downstream_impact.sql` reverses that join to find consumers.

This is the same edge table viewed from two operational questions.

## Try it

1. Find the upstream lineage of `dashboard_retention`.
2. Find the downstream impact of `raw_customers`.
3. Aggregate by asset so assets reached through several paths appear once with minimum depth.
4. Add columns for pipeline owner and freshness, then filter recursion to stale assets.
