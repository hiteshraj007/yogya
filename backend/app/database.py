from __future__ import annotations

import os
from contextlib import asynccontextmanager
from typing import Any, AsyncGenerator

from psycopg import AsyncConnection
from psycopg.rows import dict_row
from psycopg_pool import AsyncConnectionPool

# Global pool variable. If DATABASE_URL is not configured, the API keeps running
# with local seed data instead of crashing at startup.
_pool: AsyncConnectionPool | None = None
_db_disabled = False


def get_db_url() -> str:
    url = os.getenv("DATABASE_URL")
    if not url:
        raise ValueError("DATABASE_URL environment variable is not set")
    return url


async def init_db() -> None:
    """Initialize the connection pool and run schema.sql if needed."""
    global _pool, _db_disabled
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        _db_disabled = True
        return
    
    _pool = AsyncConnectionPool(
        db_url,
        min_size=1,
        max_size=10,
        kwargs={"row_factory": dict_row},
        open=False,
    )
    await _pool.open()
    
    # Check if tables exist, if not run schema
    async with get_connection() as conn:
        async with conn.cursor() as cur:
            await cur.execute(
                """
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name = 'exam_criteria'
                );
                """
            )
            exists = (await cur.fetchone())["exists"]
            if not exists:
                schema_path = os.path.join(
                    os.path.dirname(os.path.dirname(__file__)), "sql", "schema.sql"
                )
                if os.path.exists(schema_path):
                    with open(schema_path, "r") as f:
                        schema_sql = f.read()
                    await cur.execute(schema_sql)
                    await conn.commit()
                
                seed_path = os.path.join(
                    os.path.dirname(os.path.dirname(__file__)), "sql", "seed_exam_sources.sql"
                )
                if os.path.exists(seed_path):
                    with open(seed_path, "r") as f:
                        seed_sql = f.read()
                    await cur.execute(seed_sql)
                    await conn.commit()

            await cur.execute(
                """
                DO $$
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1
                        FROM pg_constraint
                        WHERE conname = 'exam_registration_status_exam_short_name_key'
                    ) THEN
                        ALTER TABLE exam_registration_status
                        ADD CONSTRAINT exam_registration_status_exam_short_name_key
                        UNIQUE (exam_short_name);
                    END IF;
                END $$;
                """
            )
            await conn.commit()


async def close_db() -> None:
    """Close the connection pool."""
    global _pool, _db_disabled
    if _pool:
        await _pool.close()
        _pool = None
    _db_disabled = False


@asynccontextmanager
async def get_connection() -> AsyncGenerator[AsyncConnection, None]:
    """Get a connection from the pool."""
    if _pool is None:
        raise RuntimeError("Database pool is not initialized. Call init_db() first.")
    
    async with _pool.connection() as conn:
        yield conn


async def fetch_one(query: str, *args: Any) -> dict[str, Any] | None:
    if _db_disabled:
        return None
    async with get_connection() as conn:
        async with conn.cursor() as cur:
            await cur.execute(query, args)
            return await cur.fetchone()


async def fetch_all(query: str, *args: Any) -> list[dict[str, Any]]:
    if _db_disabled:
        return []
    async with get_connection() as conn:
        async with conn.cursor() as cur:
            await cur.execute(query, args)
            return await cur.fetchall()


async def execute(query: str, *args: Any) -> None:
    if _db_disabled:
        return
    async with get_connection() as conn:
        async with conn.cursor() as cur:
            await cur.execute(query, args)
            await conn.commit()
