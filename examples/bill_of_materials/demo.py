from __future__ import annotations

import argparse

from examples.common import initialize_example, read_example_sql
from scripts.common import connect


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the bill of materials demo.")
    parser.add_argument("--part", default="bicycle")
    parser.add_argument("--max-depth", type=int, default=8)
    args = parser.parse_args()

    parameters = {"part": args.part, "max_depth": args.max_depth}
    with connect() as connection:
        initialize_example(connection, "bill_of_materials")
        exploded = connection.execute(
            read_example_sql("bill_of_materials", "queries/01_explode.sql"),
            parameters,
        ).fetchall()
        totals = connection.execute(
            read_example_sql("bill_of_materials", "queries/02_totals.sql"),
            parameters,
        ).fetchall()

    print(f"Exploded bill of materials for {args.part}:")
    for row in exploded:
        print(f"  {row['required_quantity']:>6} x {row['path']}")

    print("\nAggregated requirements:")
    for row in totals:
        print(f"  {row['name']:<12} {row['total_required']:>6}")


if __name__ == "__main__":
    main()
