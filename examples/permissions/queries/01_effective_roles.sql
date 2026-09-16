WITH RECURSIVE role_closure AS (
    SELECT
        role.id AS role_id,
        role.name AS role_name,
        0::INTEGER AS depth,
        ARRAY[role.id]::BIGINT[] AS path_ids,
        ARRAY[role.name]::TEXT[] AS path_names
    FROM rbac.users AS account
    JOIN rbac.user_roles ON user_roles.user_id = account.id
    JOIN rbac.roles AS role ON role.id = user_roles.role_id
    WHERE account.name = %(user)s

    UNION ALL

    SELECT
        inherited.id,
        inherited.name,
        closure.depth + 1,
        closure.path_ids || inherited.id,
        closure.path_names || inherited.name
    FROM role_closure AS closure
    JOIN rbac.role_inheritance AS inheritance
        ON inheritance.role_id = closure.role_id
    JOIN rbac.roles AS inherited
        ON inherited.id = inheritance.inherited_role_id
    WHERE closure.depth < %(max_depth)s
      AND NOT (inherited.id = ANY(closure.path_ids))
)
SELECT
    depth,
    role_name,
    array_to_string(path_names, ' -> ') AS inheritance_path
FROM role_closure
ORDER BY depth, inheritance_path;
