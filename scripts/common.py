from __future__ import annotations

import os
from pathlib import Path

import psycopg
from psycopg.rows import dict_row


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def connect() -> psycopg.Connection:
    """Open a database connection using DATABASE_URL or the Compose defaults."""

    database_url = os.getenv(
        "DATABASE_URL",
        "postgresql://graph_user:graph_password@localhost:55450/graphdb",
    )
    return psycopg.connect(database_url, row_factory=dict_row)


def load_query(filename: str) -> str:
    """Load one of the teaching queries from sql/queries."""

    query_path = PROJECT_ROOT / "sql" / "queries" / filename
    return query_path.read_text(encoding="utf-8")


def ensure_nodes_exist(connection: psycopg.Connection, *names: str) -> None:
    """Exit with a clear CLI error if any requested graph node is missing."""

    unique_names = list(dict.fromkeys(names))
    rows = connection.execute(
        "SELECT name FROM graph_nodes WHERE name = ANY(%s)",
        (unique_names,),
    ).fetchall()
    found_names = {row["name"] for row in rows}
    missing_names = [name for name in unique_names if name not in found_names]

    if missing_names:
        label = "node" if len(missing_names) == 1 else "nodes"
        rendered_names = ", ".join(repr(name) for name in missing_names)
        raise SystemExit(f"Unknown {label}: {rendered_names}.")
