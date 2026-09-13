from __future__ import annotations

import argparse

from scripts.common import connect, ensure_nodes_exist, load_query


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Walk all reachable nodes from a starting node."
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
            load_query("01_walk.sql"),
            {"start": args.start, "max_depth": args.max_depth},
        ).fetchall()

    print(f"Reachable nodes from {args.start!r}:")
    for row in rows:
        relationship = row["via_relationship"] or "start"
        print(
            f"{row['depth']:>2}  {row['name']:<18} "
            f"{row['kind']:<14} via {relationship:<12} {row['path']}"
        )


if __name__ == "__main__":
    main()
