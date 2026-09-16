WITH RECURSIVE
target AS (
    SELECT id FROM routes.locations WHERE name = %(target)s
),
paths AS (
    SELECT
        location.id AS current_id,
        0::INTEGER AS depth,
        0::NUMERIC AS total_distance_km,
        ARRAY[location.id]::BIGINT[] AS path_ids,
        ARRAY[location.name]::TEXT[] AS path_names
    FROM routes.locations AS location
    WHERE location.name = %(source)s

    UNION ALL

    SELECT
        destination.id,
        paths.depth + 1,
        paths.total_distance_km + connection.distance_km,
        paths.path_ids || destination.id,
        paths.path_names || destination.name
    FROM paths
    JOIN routes.connections AS connection
        ON connection.from_location_id = paths.current_id
    JOIN routes.locations AS destination
        ON destination.id = connection.to_location_id
    WHERE paths.depth < %(max_depth)s
      AND NOT (destination.id = ANY(paths.path_ids))
)
SELECT
    depth,
    total_distance_km,
    array_to_string(path_names, ' -> ') AS path
FROM paths
JOIN target ON target.id = paths.current_id
ORDER BY total_distance_km, depth, path
LIMIT 1;
