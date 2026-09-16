from __future__ import annotations

import argparse

from examples.common import initialize_example, read_example_sql
from scripts.common import connect


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the permission inheritance demo.")
    parser.add_argument("--user", default="alice")
    parser.add_argument("--max-depth", type=int, default=8)
    args = parser.parse_args()

    parameters = {"user": args.user, "max_depth": args.max_depth}
    with connect() as connection:
        initialize_example(connection, "permissions")
        roles = connection.execute(
            read_example_sql("permissions", "queries/01_effective_roles.sql"),
            parameters,
        ).fetchall()
        permissions = connection.execute(
            read_example_sql("permissions", "queries/02_effective_permissions.sql"),
            parameters,
        ).fetchall()

    print(f"Role paths for {args.user}:")
    for row in roles:
        print(f"  depth {row['depth']}: {row['inheritance_path']}")

    print("\nEffective permissions (deduplicated):")
    for row in permissions:
        print(f"  {row['permission']:<16} via {row['granted_by_role']}")


if __name__ == "__main__":
    main()
