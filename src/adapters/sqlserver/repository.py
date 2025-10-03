# python
from typing import Iterable, Dict, Any
from core.ports.destination_repository import DestinationRepository

class SQLServerRepository(DestinationRepository):
    def __init__(self, conn):
        self._conn = conn

    def begin_transaction(self) -> None:
        # begin TX on real connection
        pass

    def commit(self) -> None:
        pass

    def rollback(self) -> None:
        pass

    def upsert_artists(self, records: Iterable[Dict[str, Any]]) -> int:
        # Real implementation: bulk insert into staging table + MERGE
        return 0
