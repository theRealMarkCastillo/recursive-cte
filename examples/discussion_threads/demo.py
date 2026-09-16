from __future__ import annotations

import argparse

from examples.common import initialize_example, read_example_sql
from scripts.common import connect


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the discussion thread demo.")
    parser.add_argument("--thread", default="recursive-cte-tips")
    parser.add_argument("--comment", default="reply-erin")
    parser.add_argument("--max-depth", type=int, default=8)
    args = parser.parse_args()

    with connect() as connection:
        initialize_example(connection, "discussion_threads")
        thread = connection.execute(
            read_example_sql("discussion_threads", "queries/01_thread.sql"),
            {"thread": args.thread, "max_depth": args.max_depth},
        ).fetchall()
        ancestors = connection.execute(
            read_example_sql("discussion_threads", "queries/02_ancestors.sql"),
            {"comment": args.comment, "max_depth": args.max_depth},
        ).fetchall()

    print(f"Thread {args.thread}:")
    for row in thread:
        print(f"  {row['display_line']}")

    print(f"\nConversation path to {args.comment}:")
    print("  " + " -> ".join(row["comment_key"] for row in ancestors))


if __name__ == "__main__":
    main()
