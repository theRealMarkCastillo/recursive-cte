from __future__ import annotations

import argparse

from scripts.common import connect, load_query


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Walk all reachable nodes from a starting node."
    )
    parser.add_argument(
        "--start",
        default="storefront",
        help="node name to start at (default: storefront)",
    )
    args = parser.parse_args()

    with connect() as connection:
        rows = connection.execute(
            load_query("01_walk.sql"), {"start": args.start}
        ).fetchall()

    if not rows:
        raise SystemExit(f"No node named {args.start!r} was found.")

    print(f"Reachable nodes from {args.start!r}:")
    for row in rows:
        relationship = row["via_relationship"] or "start"
        print(
            f"{row['depth']:>2}  {row['name']:<18} "
            f"{row['kind']:<14} via {relationship:<12} {row['path']}"
        )


if __name__ == "__main__":
    main()
