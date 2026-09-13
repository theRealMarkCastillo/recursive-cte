-- Enumerate every simple path from :source to :target up to :max_depth hops.
WITH RECURSIVE
target AS (
    SELECT id
    FROM graph_nodes
    WHERE name = %(target)s
),
paths AS (
    -- Anchor member.
    SELECT
        source.id AS current_id,
        0::INTEGER AS depth,
        ARRAY[source.id]::BIGINT[] AS path_ids,
        ARRAY[source.name]::TEXT[] AS path_names,
        ARRAY[]::TEXT[] AS relationships
    FROM graph_nodes AS source
    WHERE source.name = %(source)s

    UNION ALL

    -- Recursive member. The depth limit is a second safety guard in addition
    -- to the simple-path check.
    SELECT
        child.id,
        p.depth + 1,
        p.path_ids || child.id,
        p.path_names || child.name,
        p.relationships || e.relationship
    FROM paths AS p
    JOIN graph_edges AS e ON e.from_node_id = p.current_id
    JOIN graph_nodes AS child ON child.id = e.to_node_id
    WHERE p.depth < %(max_depth)s
      AND NOT (child.id = ANY(p.path_ids))
)
SELECT
    p.depth,
    array_to_string(p.path_names, ' -> ') AS path,
    array_to_string(p.relationships, ', ') AS relationships
FROM paths AS p
JOIN target AS t ON t.id = p.current_id
ORDER BY p.depth, path;
