from __future__ import annotations

import argparse

from scripts.common import connect, ensure_nodes_exist, load_query


def main() -> None:
    parser = argparse.ArgumentParser(
        description="List every simple path between two nodes."
    )
    parser.add_argument("source", nargs="?", default="storefront")
    parser.add_argument("target", nargs="?", default="postgres")
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
        ensure_nodes_exist(connection, args.source, args.target)
        rows = connection.execute(
            load_query("02_find_paths.sql"),
            {
                "source": args.source,
                "target": args.target,
                "max_depth": args.max_depth,
            },
        ).fetchall()

    if not rows:
        print(
            f"No simple path found from {args.source!r} to {args.target!r} "
            f"within {args.max_depth} hops."
        )
        return

    print(f"Simple paths from {args.source!r} to {args.target!r}:")
    for number, row in enumerate(rows, start=1):
        print(f"{number:>2}. ({row['depth']} hops) {row['path']}")
        print(f"    relationships: {row['relationships']}")


if __name__ == "__main__":
    main()
