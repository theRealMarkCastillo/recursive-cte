INSERT INTO rbac.users (name)
VALUES ('alice'), ('bob')
ON CONFLICT (name) DO NOTHING;

INSERT INTO rbac.roles (name)
VALUES ('viewer'), ('editor'), ('auditor'), ('admin')
ON CONFLICT (name) DO NOTHING;

INSERT INTO rbac.permissions (name)
VALUES ('read_reports'), ('edit_content'), ('view_audit_log'), ('manage_users')
ON CONFLICT (name) DO NOTHING;

INSERT INTO rbac.user_roles (user_id, role_id)
SELECT users.id, roles.id
FROM (VALUES ('alice', 'admin'), ('bob', 'editor')) AS seeded(user_name, role_name)
JOIN rbac.users ON users.name = seeded.user_name
JOIN rbac.roles ON roles.name = seeded.role_name
ON CONFLICT DO NOTHING;

INSERT INTO rbac.role_inheritance (role_id, inherited_role_id)
SELECT roles.id, inherited.id
FROM (
    VALUES
        ('editor', 'viewer'),
        ('auditor', 'viewer'),
        ('admin', 'editor'),
        ('admin', 'auditor')
) AS seeded(role_name, inherited_name)
JOIN rbac.roles ON roles.name = seeded.role_name
JOIN rbac.roles AS inherited ON inherited.name = seeded.inherited_name
ON CONFLICT DO NOTHING;

INSERT INTO rbac.role_permissions (role_id, permission_id)
SELECT roles.id, permissions.id
FROM (
    VALUES
        ('viewer', 'read_reports'),
        ('editor', 'edit_content'),
        ('auditor', 'view_audit_log'),
        ('admin', 'manage_users')
) AS seeded(role_name, permission_name)
JOIN rbac.roles ON roles.name = seeded.role_name
JOIN rbac.permissions ON permissions.name = seeded.permission_name
ON CONFLICT DO NOTHING;
