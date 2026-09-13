-- Find the nearest distance to every reachable node and count how many
-- simple paths reach it. Aggregation happens after recursion.
WITH RECURSIVE reachable AS (
    SELECT
        n.id,
        n.name,
        0::INTEGER AS depth,
        ARRAY[n.id]::BIGINT[] AS path_ids
    FROM graph_nodes AS n
    WHERE n.name = %(start)s

    UNION ALL

    SELECT
        child.id,
        child.name,
        r.depth + 1,
        r.path_ids || child.id
    FROM reachable AS r
    JOIN graph_edges AS e ON e.from_node_id = r.id
    JOIN graph_nodes AS child ON child.id = e.to_node_id
    WHERE r.depth < %(max_depth)s
      AND NOT (child.id = ANY(r.path_ids))
)
SELECT
    name,
    MIN(depth) AS min_hops,
    COUNT(*) AS simple_path_count
FROM reachable
WHERE depth > 0
GROUP BY id, name
ORDER BY min_hops, name;
