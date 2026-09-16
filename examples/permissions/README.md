# Permission inheritance

## Question

Which permissions does a user receive through directly assigned and inherited roles?

```text
alice --> admin
            |--inherits--> editor ----inherits----+
            |                                      v
            `--inherits--> auditor ---inherits--> viewer

admin:   manage_users
editor:  edit_content
auditor: view_audit_log
viewer:  read_reports
```

## Why this is a DAG

`viewer` is reachable from `admin` through both `editor` and `auditor`. The role-path query intentionally shows both paths. The effective-permission query uses `DISTINCT` so `read_reports` is granted once.

## Run

```sh
make demo-rbac
```

Try Bob, who is assigned only `editor`:

```sh
python -m examples.permissions.demo --user bob
```

## Read the SQL

- `queries/01_effective_roles.sql` exposes every simple inheritance path.
- `queries/02_effective_permissions.sql` joins the role closure to grants and deduplicates the result.

## Try it

1. Predict Bob's permissions before running the demo.
2. Give Alice both `admin` and `viewer` directly; observe duplicate role paths but stable effective permissions.
3. Add a cycle between two temporary roles and verify the visited-role array terminates it.
4. In a real system, add tenant and account scope inside both the anchor and recursive member—not only in the final `SELECT`.
