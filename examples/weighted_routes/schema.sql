CREATE SCHEMA IF NOT EXISTS routes;

CREATE TABLE IF NOT EXISTS routes.locations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS routes.connections (
    from_location_id BIGINT NOT NULL
        REFERENCES routes.locations(id) ON DELETE CASCADE,
    to_location_id BIGINT NOT NULL
        REFERENCES routes.locations(id) ON DELETE CASCADE,
    distance_km NUMERIC(10, 2) NOT NULL CHECK (distance_km > 0),
    travel_minutes INTEGER NOT NULL CHECK (travel_minutes > 0),
    PRIMARY KEY (from_location_id, to_location_id),
    CHECK (from_location_id <> to_location_id)
);

CREATE INDEX IF NOT EXISTS connections_destination_idx
    ON routes.connections (to_location_id);
