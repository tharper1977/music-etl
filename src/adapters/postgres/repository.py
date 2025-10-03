# python
from typing import Iterable, Dict, Any
from core.ports.source_repository import SourceRepository

class PostgresRepository(SourceRepository):
    def __init__(self, conn):
        self._conn = conn

    def fetch_artists_batch(self, offset: int, limit: int) -> Iterable[Dict[str, Any]]:
        # Minimal stub: real implementation should use server-side cursor and SQL
        # Here we return an empty list as placeholder
        return []
