CREATE SCHEMA IF NOT EXISTS org;

CREATE TABLE IF NOT EXISTS org.employees (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    manager_id BIGINT REFERENCES org.employees(id),
    CHECK (manager_id IS NULL OR manager_id <> id)
);

CREATE INDEX IF NOT EXISTS employees_manager_idx
    ON org.employees (manager_id);
