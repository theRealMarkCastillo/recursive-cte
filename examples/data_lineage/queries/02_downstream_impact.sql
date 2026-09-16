WITH RECURSIVE impact AS (
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
        consumer.id,
        consumer.name,
        consumer.asset_type,
        impact.depth + 1,
        impact.path_ids || consumer.id,
        impact.path_names || consumer.name
    FROM impact
    JOIN lineage.dependencies AS dependency
        ON dependency.upstream_asset_id = impact.id
    JOIN lineage.assets AS consumer
        ON consumer.id = dependency.downstream_asset_id
    WHERE impact.depth < %(max_depth)s
      AND NOT (consumer.id = ANY(impact.path_ids))
)
SELECT
    depth,
    name,
    asset_type,
    array_to_string(path_names, ' -> ') AS impact_path
FROM impact
ORDER BY depth, impact_path;
