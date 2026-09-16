WITH RECURSIVE upstream AS (
    SELECT
        asset.id,
        asset.name,
        asset.asset_type,
        0::INTEGER AS depth,
        ARRAY[asset.id]::BIGINT[] AS path_ids,
        ARRAY[asset.name]::TEXT[] AS path_names
    FROM lineage.assets AS asset
    WHERE asset.name = %(asset)s

    UNION ALL

    SELECT
        source.id,
        source.name,
        source.asset_type,
        upstream.depth + 1,
        upstream.path_ids || source.id,
        upstream.path_names || source.name
    FROM upstream
    JOIN lineage.dependencies AS dependency
        ON dependency.downstream_asset_id = upstream.id
    JOIN lineage.assets AS source ON source.id = dependency.upstream_asset_id
    WHERE upstream.depth < %(max_depth)s
      AND NOT (source.id = ANY(upstream.path_ids))
)
SELECT
    depth,
    name,
    asset_type,
    array_to_string(path_names, ' <- ') AS path
FROM upstream
ORDER BY depth, path;
