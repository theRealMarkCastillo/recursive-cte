from __future__ import annotations

import argparse

from scripts.common import connect, ensure_nodes_exist, load_query


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Find a shortest path by number of hops."
    )
    parser.add_argument("source", nargs="?", default="storefront")
    parser.add_argument("target", nargs="?", default="postgres")
    parser.add_argument(
        "--max-depth",
        type=int,
        default=8,
        help="maximum number of hops considered (default: 8)",
    )
    args = parser.parse_args()
    if args.max_depth < 0:
        parser.error("--max-depth must be zero or greater")

    with connect() as connection:
        ensure_nodes_exist(connection, args.source, args.target)
        row = connection.execute(
            load_query("03_shortest_path.sql"),
            {
                "source": args.source,
                "target": args.target,
                "max_depth": args.max_depth,
            },
        ).fetchone()

    if row is None:
        print(
            f"No path found from {args.source!r} to {args.target!r} "
            f"within {args.max_depth} hops."
        )
        return

    print(
        f"Shortest path from {args.source!r} to {args.target!r} "
        f"({row['depth']} hops):"
    )
    print(f"  {row['path']}")
    print(f"  relationships: {row['relationships']}")


if __name__ == "__main__":
    main()
