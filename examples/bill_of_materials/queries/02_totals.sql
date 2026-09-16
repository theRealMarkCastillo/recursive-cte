WITH RECURSIVE exploded AS (
    SELECT
        part.id,
        part.name,
        part.part_type,
        0::INTEGER AS depth,
        1::NUMERIC AS required_quantity,
        ARRAY[part.id]::BIGINT[] AS path_ids
    FROM bom.parts AS part
    WHERE part.name = %(part)s

    UNION ALL

    SELECT
        child.id,
        child.name,
        child.part_type,
        exploded.depth + 1,
        exploded.required_quantity * component.quantity,
        exploded.path_ids || child.id
    FROM exploded
    JOIN bom.components AS component ON component.parent_part_id = exploded.id
    JOIN bom.parts AS child ON child.id = component.child_part_id
    WHERE exploded.depth < %(max_depth)s
      AND NOT (child.id = ANY(exploded.path_ids))
)
SELECT
    name,
    part_type,
    SUM(required_quantity) AS total_required
FROM exploded
WHERE depth > 0
GROUP BY id, name, part_type
ORDER BY part_type, name;
