from __future__ import annotations

import argparse

from scripts.common import connect, ensure_nodes_exist, load_query


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Summarize nearest distance and path counts for a node."
    )
    parser.add_argument(
        "--start",
        default="storefront",
        help="node name to start at (default: storefront)",
    )
    parser.add_argument(
        "--max-depth",
        type=int,
        default=8,
        help="maximum number of hops (default: 8)",
    )
    args = parser.parse_args()
    if args.max_depth < 0:
        parser.error("--max-depth must be zero or greater")

    with connect() as connection:
        ensure_nodes_exist(connection, args.start)
        rows = connection.execute(
            load_query("04_dependency_summary.sql"),
            {"start": args.start, "max_depth": args.max_depth},
        ).fetchall()

    if not rows:
        print(f"No dependencies reachable from {args.start!r}.")
        return

    print(f"Dependencies reachable from {args.start!r}:")
    print("node                 nearest hops  simple paths")
    print("-------------------  -------------  -------------")
    for row in rows:
        print(
            f"{row['name']:<19}  {row['min_hops']:>13}  "
            f"{row['simple_path_count']:>13}"
        )


if __name__ == "__main__":
    main()
