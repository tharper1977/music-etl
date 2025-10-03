# python
from typing import Iterable, List
from core.ports.source_repository import SourceRepository
from core.ports.destination_repository import DestinationRepository
from core.ports.mapper import Mapper
from core.models import Artist

class ETLService:
    def __init__(self, src: SourceRepository, dst: DestinationRepository, mapper: Mapper, batch_size: int = 500):
        self.src = src
        self.dst = dst
        self.mapper = mapper
        self.batch_size = batch_size

    def run_full_load(self) -> None:
        offset = 0
        while True:
            rows = list(self.src.fetch_artists_batch(offset, self.batch_size))
            if not rows:
                break
            domain_objs: List[Artist] = [self.mapper.map_source_artist_to_domain(r) for r in rows]
            dest_rows = [self.mapper.map_artist_to_destination(a) for a in domain_objs]
            try:
                self.dst.begin_transaction()
                self.dst.upsert_artists(dest_rows)
                self.dst.commit()
            except Exception:
                self.dst.rollback()
                raise
            offset += len(rows)
