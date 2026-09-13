-- Start at one node and visit every reachable node once per simple path.
-- The path_ids array is the cycle guard: do not visit a vertex already in
-- the current path.
WITH RECURSIVE walk AS (
    -- Anchor member: one row for the starting vertex.
    SELECT
        n.id,
        n.name,
        n.kind,
        0::INTEGER AS depth,
        ARRAY[n.id]::BIGINT[] AS path_ids,
        ARRAY[n.name]::TEXT[] AS path_names,
        NULL::TEXT AS via_relationship
    FROM graph_nodes AS n
    WHERE n.name = %(start)s

    UNION ALL

    -- Recursive member: follow each outgoing edge to the next vertex.
    SELECT
        child.id,
        child.name,
        child.kind,
        w.depth + 1,
        w.path_ids || child.id,
        w.path_names || child.name,
        e.relationship
    FROM walk AS w
    JOIN graph_edges AS e ON e.from_node_id = w.id
    JOIN graph_nodes AS child ON child.id = e.to_node_id
    WHERE NOT (child.id = ANY(w.path_ids))
)
SELECT
    depth,
    name,
    kind,
    via_relationship,
    array_to_string(path_names, ' -> ') AS path
FROM walk
ORDER BY depth, path;
