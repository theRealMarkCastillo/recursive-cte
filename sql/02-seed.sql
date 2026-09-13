INSERT INTO graph_nodes (name, kind)
VALUES
    ('storefront', 'service'),
    ('api', 'service'),
    ('auth', 'service'),
    ('catalog', 'service'),
    ('orders', 'service'),
    ('payments', 'service'),
    ('inventory', 'service'),
    ('pricing', 'service'),
    ('legacy_tax_rules', 'library'),
    ('postgres', 'database'),
    ('redis', 'cache'),
    ('worker', 'service'),
    ('queue', 'infrastructure'),
    ('reporting', 'service')
ON CONFLICT (name) DO NOTHING;

-- An edge points from the caller/consumer to the service or resource it uses.
-- The pricing <-> legacy_tax_rules pair is intentional: it gives us a cycle
-- to make cycle protection visible in the recursive queries.
INSERT INTO graph_edges (from_node_id, to_node_id, relationship, weight)
SELECT source.id, target.id, seeded.relationship, seeded.weight
FROM (
    VALUES
        ('storefront', 'api', 'calls', 1),
        ('api', 'auth', 'calls', 1),
        ('api', 'catalog', 'calls', 1),
        ('api', 'orders', 'calls', 1),
        ('api', 'pricing', 'calls', 1),
        ('api', 'redis', 'reads_from', 1),
        ('orders', 'payments', 'calls', 2),
        ('orders', 'inventory', 'calls', 2),
        ('orders', 'postgres', 'reads_from', 1),
        ('catalog', 'postgres', 'reads_from', 1),
        ('payments', 'postgres', 'reads_from', 1),
        ('inventory', 'postgres', 'reads_from', 1),
        ('pricing', 'postgres', 'reads_from', 1),
        ('pricing', 'legacy_tax_rules', 'imports', 2),
        ('legacy_tax_rules', 'pricing', 'depends_on', 2),
        ('worker', 'queue', 'consumes', 1),
        ('worker', 'postgres', 'writes_to', 1),
        ('reporting', 'postgres', 'reads_from', 1),
        ('reporting', 'queue', 'consumes', 1)
) AS seeded(source_name, target_name, relationship, weight)
JOIN graph_nodes AS source ON source.name = seeded.source_name
JOIN graph_nodes AS target ON target.name = seeded.target_name
ON CONFLICT (from_node_id, to_node_id) DO UPDATE
SET relationship = EXCLUDED.relationship,
    weight = EXCLUDED.weight;
