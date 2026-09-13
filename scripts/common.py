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
