WITH RECURSIVE exploded AS (
    SELECT
        part.id,
        part.name,
        part.part_type,
        0::INTEGER AS depth,
        1::NUMERIC AS required_quantity,
        ARRAY[part.id]::BIGINT[] AS path_ids,
        ARRAY[part.name]::TEXT[] AS path_names
    FROM bom.parts AS part
    WHERE part.name = %(part)s

    UNION ALL

    SELECT
        child.id,
        child.name,
        child.part_type,
        exploded.depth + 1,
        exploded.required_quantity * component.quantity,
        exploded.path_ids || child.id,
        exploded.path_names || child.name
    FROM exploded
    JOIN bom.components AS component ON component.parent_part_id = exploded.id
    JOIN bom.parts AS child ON child.id = component.child_part_id
    WHERE exploded.depth < %(max_depth)s
      AND NOT (child.id = ANY(exploded.path_ids))
)
SELECT
    depth,
    name,
    part_type,
    required_quantity,
    array_to_string(path_names, ' -> ') AS path
FROM exploded
WHERE depth > 0
ORDER BY path_names;
