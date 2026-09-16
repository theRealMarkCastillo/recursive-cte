INSERT INTO bom.parts (name, part_type)
VALUES
    ('bicycle', 'product'),
    ('wheel', 'assembly'),
    ('frame', 'assembly'),
    ('seat', 'assembly'),
    ('handlebar', 'assembly'),
    ('spoke', 'component'),
    ('rim', 'component'),
    ('hub', 'component'),
    ('tire', 'component'),
    ('tube', 'component'),
    ('bolt', 'component'),
    ('grip', 'component')
ON CONFLICT (name) DO UPDATE SET part_type = EXCLUDED.part_type;

INSERT INTO bom.components (parent_part_id, child_part_id, quantity)
SELECT parent.id, child.id, seeded.quantity
FROM (
    VALUES
        ('bicycle', 'wheel', 2.0),
        ('bicycle', 'frame', 1.0),
        ('bicycle', 'seat', 1.0),
        ('bicycle', 'handlebar', 1.0),
        ('wheel', 'spoke', 36.0),
        ('wheel', 'rim', 1.0),
        ('wheel', 'hub', 1.0),
        ('wheel', 'tire', 1.0),
        ('wheel', 'tube', 1.0),
        ('frame', 'bolt', 4.0),
        ('seat', 'bolt', 2.0),
        ('handlebar', 'grip', 2.0),
        ('handlebar', 'bolt', 2.0)
) AS seeded(parent_name, child_name, quantity)
JOIN bom.parts AS parent ON parent.name = seeded.parent_name
JOIN bom.parts AS child ON child.name = seeded.child_name
ON CONFLICT (parent_part_id, child_part_id) DO UPDATE
SET quantity = EXCLUDED.quantity;
