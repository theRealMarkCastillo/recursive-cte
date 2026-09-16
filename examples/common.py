from __future__ import annotations

from pathlib import Path

import psycopg


EXAMPLES_ROOT = Path(__file__).resolve().parent
EXAMPLE_NAMES = (
    "org_chart",
    "bill_of_materials",
    "permissions",
    "data_lineage",
    "discussion_threads",
    "weighted_routes",
)


def read_example_sql(example_name: str, relative_path: str) -> str:
    """Read SQL belonging to one practical example."""

    if example_name not in EXAMPLE_NAMES:
        raise ValueError(f"Unknown example: {example_name}")
    return (EXAMPLES_ROOT / example_name / relative_path).read_text(encoding="utf-8")


def initialize_example(
    connection: psycopg.Connection, example_name: str
) -> None:
    """Create and idempotently seed one example schema."""

    connection.execute(read_example_sql(example_name, "schema.sql"))
    connection.execute(read_example_sql(example_name, "seed.sql"))


def initialize_all_examples(connection: psycopg.Connection) -> None:
    """Create and seed every practical example schema."""

    for example_name in EXAMPLE_NAMES:
        initialize_example(connection, example_name)
