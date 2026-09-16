from __future__ import annotations

import argparse

from examples.common import initialize_example, read_example_sql
from scripts.common import connect


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the weighted routes demo.")
    parser.add_argument("--source", default="Depot")
    parser.add_argument("--target", default="Store")
    parser.add_argument("--max-depth", type=int, default=6)
    args = parser.parse_args()

    parameters = {
        "source": args.source,
        "target": args.target,
        "max_depth": args.max_depth,
    }
    with connect() as connection:
        initialize_example(connection, "weighted_routes")
        paths = connection.execute(
            read_example_sql("weighted_routes", "queries/01_all_paths.sql"),
            parameters,
        ).fetchall()
        shortest_distance = connection.execute(
            read_example_sql("weighted_routes", "queries/02_shortest_distance.sql"),
            parameters,
        ).fetchone()
        fewest_hops = connection.execute(
            read_example_sql("weighted_routes", "queries/03_fewest_hops.sql"),
            parameters,
        ).fetchone()

    print(f"Candidate routes from {args.source} to {args.target}:")
    for row in paths:
        print(
            f"  {row['total_distance_km']:>5} km, "
            f"{row['total_minutes']:>2} min, {row['depth']} hops: {row['path']}"
        )

    print("\nComparison:")
    print(
        f"  shortest distance: {shortest_distance['total_distance_km']} km — "
        f"{shortest_distance['path']}"
    )
    print(
        f"  fewest hops:       {fewest_hops['depth']} hops, "
        f"{fewest_hops['total_distance_km']} km — {fewest_hops['path']}"
    )


if __name__ == "__main__":
    main()
