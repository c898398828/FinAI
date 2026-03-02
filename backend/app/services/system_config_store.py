from __future__ import annotations

import sqlite3
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parents[2]
SYSTEM_CONFIG_DIR = BASE_DIR / "data"
SYSTEM_CONFIG_DB = SYSTEM_CONFIG_DIR / "system_config.db"


def _connect() -> sqlite3.Connection:
    SYSTEM_CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(SYSTEM_CONFIG_DB)
    conn.row_factory = sqlite3.Row
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS system_config (
            config_key TEXT PRIMARY KEY,
            config_value TEXT NOT NULL,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
        """
    )
    return conn


def load_config(keys: list[str]) -> dict[str, str]:
    if not keys:
        return {}
    placeholders = ",".join("?" for _ in keys)
    with _connect() as conn:
        rows = conn.execute(
            f"SELECT config_key, config_value FROM system_config WHERE config_key IN ({placeholders})",
            keys,
        ).fetchall()
    return {str(row["config_key"]): str(row["config_value"]) for row in rows}


def save_config(values: dict[str, str]) -> None:
    if not values:
        return
    with _connect() as conn:
        conn.executemany(
            """
            INSERT INTO system_config(config_key, config_value, updated_at)
            VALUES(?, ?, CURRENT_TIMESTAMP)
            ON CONFLICT(config_key) DO UPDATE SET
                config_value = excluded.config_value,
                updated_at = CURRENT_TIMESTAMP
            """,
            [(k, v) for k, v in values.items()],
        )
        conn.commit()

