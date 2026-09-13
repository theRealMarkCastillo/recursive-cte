CREATE TABLE IF NOT EXISTS graph_nodes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    kind TEXT NOT NULL CHECK (btrim(kind) <> '')
);

CREATE TABLE IF NOT EXISTS graph_edges (
    from_node_id BIGINT NOT NULL REFERENCES graph_nodes(id) ON DELETE CASCADE,
    to_node_id BIGINT NOT NULL REFERENCES graph_nodes(id) ON DELETE CASCADE,
    relationship TEXT NOT NULL DEFAULT 'related_to'
        CHECK (btrim(relationship) <> ''),
    weight INTEGER NOT NULL DEFAULT 1 CHECK (weight >= 0),
    PRIMARY KEY (from_node_id, to_node_id)
);

CREATE INDEX IF NOT EXISTS graph_edges_to_node_idx
    ON graph_edges (to_node_id);

COMMENT ON TABLE graph_nodes IS
    'Vertices in the teaching graph.';

COMMENT ON TABLE graph_edges IS
    'Directed edges: from_node_id points to to_node_id.';
