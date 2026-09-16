CREATE SCHEMA IF NOT EXISTS lineage;

CREATE TABLE IF NOT EXISTS lineage.assets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    asset_type TEXT NOT NULL
);

-- downstream_asset_id is produced from or depends on upstream_asset_id.
CREATE TABLE IF NOT EXISTS lineage.dependencies (
    downstream_asset_id BIGINT NOT NULL
        REFERENCES lineage.assets(id) ON DELETE CASCADE,
    upstream_asset_id BIGINT NOT NULL
        REFERENCES lineage.assets(id) ON DELETE CASCADE,
    PRIMARY KEY (downstream_asset_id, upstream_asset_id),
    CHECK (downstream_asset_id <> upstream_asset_id)
);

CREATE INDEX IF NOT EXISTS dependencies_upstream_idx
    ON lineage.dependencies (upstream_asset_id);
