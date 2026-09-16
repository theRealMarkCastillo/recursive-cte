from __future__ import annotations

import argparse

from examples.common import initialize_example, read_example_sql
from scripts.common import connect


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the organization chart demo.")
    parser.add_argument("--manager", default="Alice")
    parser.add_argument("--employee", default="Erin")
    parser.add_argument("--max-depth", type=int, default=8)
    args = parser.parse_args()

    with connect() as connection:
        initialize_example(connection, "org_chart")
        reports = connection.execute(
            read_example_sql("org_chart", "queries/01_reports.sql"),
            {"manager": args.manager, "max_depth": args.max_depth},
        ).fetchall()
        chain = connection.execute(
            read_example_sql("org_chart", "queries/02_management_chain.sql"),
            {"employee": args.employee, "max_depth": args.max_depth},
        ).fetchall()

    print(f"Organization under {args.manager}:")
    for row in reports:
        print(f"  {row['organization_line']} — {row['title']}")

    print(f"\nManagement chain for {args.employee}:")
    print("  " + " -> ".join(row["name"] for row in chain))


if __name__ == "__main__":
    main()
