from typing import AsyncIterator

from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from .config import get_settings


class Base(DeclarativeBase):
    pass


_engine: AsyncEngine | None = None
_SessionLocal: async_sessionmaker[AsyncSession] | None = None


def init_engine() -> None:
    global _engine, _SessionLocal
    _engine = create_async_engine(get_settings().database_url, pool_pre_ping=True)
    _SessionLocal = async_sessionmaker(_engine, expire_on_commit=False)


async def create_all() -> None:
    assert _engine is not None
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def get_db() -> AsyncIterator[AsyncSession]:
    if _SessionLocal is None:
        init_engine()
    assert _SessionLocal is not None
    async with _SessionLocal() as session:
        yield session
