# python
# File: tests/conftest.py
from __future__ import annotations
import pytest
from datetime import datetime, timedelta
from typing import Iterable, List
from dataclasses import dataclass

# Reuse the Protocol names from core.ports.etl_ports in tests via structural typing.
# If your project names differ, adjust imports accordingly.
from core.ports.etl_ports import Extractor, Translator, Loader, LoadResult

@dataclass
class GenreIn:
    mb_id: int
    name: str
    last_updated: datetime

@dataclass
class GenreOut:
    source_id: str
    name: str
    normalized_name: str
    source_updated_at: datetime

class MockGenreExtractor(Extractor[GenreIn]):
    def __init__(self, rows: Iterable[GenreIn]):
        self._rows = list(rows)

    def extract_batch(self, since: datetime | None, limit: int):
        for r in self._rows:
            if since is None or r.last_updated > since:
                yield r

class MockGenreTranslator(Translator[GenreIn, GenreOut]):
    def translate(self, item: GenreIn) -> GenreOut:
        normalized = " ".join(item.name.strip().lower().split())
        return GenreOut(
            source_id=str(item.mb_id),
            name=item.name.strip(),
            normalized_name=normalized,
            source_updated_at=item.last_updated,
        )

    def translate_batch(self, items: Iterable[GenreIn]) -> List[GenreOut]:
        return [self.translate(i) for i in items]

class MockGenreLoader(Loader[GenreOut]):
    def __init__(self):
        # simple in-memory store keyed by normalized_name
        self.store: dict[str, dict] = {}
        self.errors: list[dict] = []

    def load_batch(self, items: Iterable[GenreOut], batch_id):
        inserted = 0
        updated = 0
        for it in items:
            key = it.normalized_name
            if key in self.store:
                # simulate update when name differs
                if self.store[key]["name"] != it.name:
                    self.store[key]["name"] = it.name
                    updated += 1
            else:
                self.store[key] = {"name": it.name, "source_id": it.source_id, "updated_at": it.source_updated_at}
                inserted += 1
        return LoadResult(inserted=inserted, updated=updated, errors=self.errors)

@pytest.fixture
def sample_genres():
    base = datetime(2020, 1, 1)
    return [
        GenreIn(mb_id=10, name="Rock", last_updated=base + timedelta(hours=1)),
        GenreIn(mb_id=11, name="Progressive Rock", last_updated=base + timedelta(hours=2)),
        GenreIn(mb_id=12, name=" electronic ", last_updated=base + timedelta(hours=3)),
    ]
