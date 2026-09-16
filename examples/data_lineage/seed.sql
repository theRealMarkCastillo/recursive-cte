INSERT INTO lineage.assets (name, asset_type)
VALUES
    ('raw_orders', 'source_table'),
    ('raw_customers', 'source_table'),
    ('stg_orders', 'staging_model'),
    ('stg_customers', 'staging_model'),
    ('dim_customer', 'warehouse_model'),
    ('fct_orders', 'warehouse_model'),
    ('customer_metrics', 'warehouse_model'),
    ('dashboard_revenue', 'dashboard'),
    ('dashboard_retention', 'dashboard')
ON CONFLICT (name) DO UPDATE SET asset_type = EXCLUDED.asset_type;

INSERT INTO lineage.dependencies (downstream_asset_id, upstream_asset_id)
SELECT downstream.id, upstream.id
FROM (
    VALUES
        ('stg_orders', 'raw_orders'),
        ('stg_customers', 'raw_customers'),
        ('dim_customer', 'stg_customers'),
        ('fct_orders', 'stg_orders'),
        ('fct_orders', 'dim_customer'),
        ('customer_metrics', 'fct_orders'),
        ('customer_metrics', 'dim_customer'),
        ('dashboard_revenue', 'fct_orders'),
        ('dashboard_retention', 'customer_metrics')
) AS seeded(downstream_name, upstream_name)
JOIN lineage.assets AS downstream ON downstream.name = seeded.downstream_name
JOIN lineage.assets AS upstream ON upstream.name = seeded.upstream_name
ON CONFLICT DO NOTHING;
