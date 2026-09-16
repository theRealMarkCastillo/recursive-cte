CREATE SCHEMA IF NOT EXISTS bom;

CREATE TABLE IF NOT EXISTS bom.parts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    part_type TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS bom.components (
    parent_part_id BIGINT NOT NULL REFERENCES bom.parts(id) ON DELETE CASCADE,
    child_part_id BIGINT NOT NULL REFERENCES bom.parts(id) ON DELETE CASCADE,
    quantity NUMERIC(12, 2) NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (parent_part_id, child_part_id),
    CHECK (parent_part_id <> child_part_id)
);

CREATE INDEX IF NOT EXISTS components_child_idx
    ON bom.components (child_part_id);
