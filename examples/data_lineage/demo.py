from __future__ import annotations

import argparse

from examples.common import initialize_example, read_example_sql
from scripts.common import connect


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the data lineage demo.")
    parser.add_argument("--asset", default="dashboard_revenue")
    parser.add_argument("--impact-source", default="raw_orders")
    parser.add_argument("--max-depth", type=int, default=8)
    args = parser.parse_args()

    with connect() as connection:
        initialize_example(connection, "data_lineage")
        upstream = connection.execute(
            read_example_sql("data_lineage", "queries/01_upstream.sql"),
            {"asset": args.asset, "max_depth": args.max_depth},
        ).fetchall()
        impact = connection.execute(
            read_example_sql("data_lineage", "queries/02_downstream_impact.sql"),
            {"asset": args.impact_source, "max_depth": args.max_depth},
        ).fetchall()

    print(f"Upstream lineage for {args.asset}:")
    for row in upstream:
        print(f"  depth {row['depth']}: {row['path']}")

    print(f"\nDownstream impact from {args.impact_source}:")
    for row in impact:
        print(f"  depth {row['depth']}: {row['impact_path']}")


if __name__ == "__main__":
    main()
