CREATE SCHEMA IF NOT EXISTS rbac;

CREATE TABLE IF NOT EXISTS rbac.users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS rbac.roles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS rbac.permissions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS rbac.user_roles (
    user_id BIGINT NOT NULL REFERENCES rbac.users(id) ON DELETE CASCADE,
    role_id BIGINT NOT NULL REFERENCES rbac.roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- role_id inherits all permissions from inherited_role_id.
CREATE TABLE IF NOT EXISTS rbac.role_inheritance (
    role_id BIGINT NOT NULL REFERENCES rbac.roles(id) ON DELETE CASCADE,
    inherited_role_id BIGINT NOT NULL REFERENCES rbac.roles(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, inherited_role_id),
    CHECK (role_id <> inherited_role_id)
);

CREATE TABLE IF NOT EXISTS rbac.role_permissions (
    role_id BIGINT NOT NULL REFERENCES rbac.roles(id) ON DELETE CASCADE,
    permission_id BIGINT NOT NULL REFERENCES rbac.permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE INDEX IF NOT EXISTS role_inheritance_parent_idx
    ON rbac.role_inheritance (inherited_role_id);
