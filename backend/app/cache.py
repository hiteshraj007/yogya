from __future__ import annotations

import json
import os
from typing import Any

import httpx
import redis.asyncio as redis


class Cache:
    def __init__(self) -> None:
        self.redis_client: redis.Redis | None = None
        self.upstash_url: str | None = None
        self.upstash_token: str | None = None

    async def init(self) -> None:
        redis_url = os.getenv("REDIS_URL")
        if redis_url:
            self.redis_client = redis.from_url(redis_url, decode_responses=True)
        else:
            self.upstash_url = os.getenv("UPSTASH_REDIS_REST_URL")
            self.upstash_token = os.getenv("UPSTASH_REDIS_REST_TOKEN")
            if self.upstash_url and self.upstash_url.endswith("/"):
                self.upstash_url = self.upstash_url[:-1]

    async def close(self) -> None:
        if self.redis_client:
            await self.redis_client.aclose()

    async def get(self, key: str) -> Any | None:
        if self.redis_client:
            data = await self.redis_client.get(key)
            return json.loads(data) if data else None

        if self.upstash_url and self.upstash_token:
            async with httpx.AsyncClient() as client:
                res = await client.get(
                    f"{self.upstash_url}/get/{key}",
                    headers={"Authorization": f"Bearer {self.upstash_token}"},
                )
                if res.status_code == 200:
                    data = res.json()
                    if data.get("result"):
                        try:
                            return json.loads(data["result"])
                        except json.JSONDecodeError:
                            return data["result"]
        return None

    async def set(self, key: str, value: Any, ttl_seconds: int | None = None) -> None:
        str_val = json.dumps(value)
        if self.redis_client:
            await self.redis_client.set(key, str_val, ex=ttl_seconds)
            return

        if self.upstash_url and self.upstash_token:
            async with httpx.AsyncClient() as client:
                url = f"{self.upstash_url}/set/{key}"
                if ttl_seconds:
                    url += f"?EX={ttl_seconds}"
                await client.post(
                    url,
                    headers={"Authorization": f"Bearer {self.upstash_token}"},
                    content=str_val,
                )

    async def delete(self, key: str) -> None:
        if self.redis_client:
            await self.redis_client.delete(key)
            return

        if self.upstash_url and self.upstash_token:
            async with httpx.AsyncClient() as client:
                await client.get(
                    f"{self.upstash_url}/del/{key}",
                    headers={"Authorization": f"Bearer {self.upstash_token}"},
                )

    async def clear_pattern(self, pattern: str) -> None:
        if self.redis_client:
            keys = await self.redis_client.keys(pattern)
            if keys:
                await self.redis_client.delete(*keys)
            return

        # Upstash REST: getting keys and then deleting
        if self.upstash_url and self.upstash_token:
            async with httpx.AsyncClient() as client:
                res = await client.get(
                    f"{self.upstash_url}/keys/{pattern}",
                    headers={"Authorization": f"Bearer {self.upstash_token}"},
                )
                if res.status_code == 200:
                    keys = res.json().get("result", [])
                    for k in keys:
                        await self.delete(k)

cache = Cache()
