# python
# file: src/application/services/simple_examples.py

"""
Simple in-memory example implementations of Extractor/Translator/Loader for Country lookup.
These are useful for local unit tests and demonstration of the orchestrator flow.
"""

from __future__ import annotations
from typing import Iterable, List, Optional
from datetime import datetime
from uuid import UUID, uuid4
from dataclasses import dataclass

from core.ports.etl_ports import Extractor, Translator, Loader, ExtractedRow, LoadResult

# Example TIn / TOut shapes
@dataclass
class CountryIn:
    mb_id: int
    iso_code: Optional[str]
    name: str
    last_updated: Optional[datetime]

@dataclass
class CountryOut:
    source_id: str  # mb_id as string
    code: Optional[str]
    name: str
    normalized_name: str
    source_updated_at: Optional[datetime]

class InMemoryCountryExtractor(Extractor[CountryIn]):
    def __init__(self, rows: Iterable[CountryIn]):
        self._rows = list(rows)

    def extract_batch(self, since: Optional[datetime], limit: int) -> Iterable[CountryIn]:
        # naive implementation: filter by last_updated
        for r in self._rows:
            if since is None or (r.last_updated and r.last_updated > since):
                yield r

class CountryTranslator(Translator[CountryIn, CountryOut]):
    def translate(self, item: CountryIn) -> CountryOut:
        normalized = " ".join(item.name.strip().lower().split())
        code = (item.iso_code or "").upper() if item.iso_code else None
        return CountryOut(
            source_id=str(item.mb_id),
            code=code,
            name=item.name.strip(),
            normalized_name=normalized,
            source_updated_at=item.last_updated,
        )

    def translate_batch(self, items: Iterable[CountryIn]) -> List[CountryOut]:
        return [self.translate(i) for i in items]

class InMemoryLoader(Loader[CountryOut]):
    def __init__(self):
        # in-memory "destination" table keyed by (code or name)
        self.store = {}
        self._inserted = 0
        self._updated = 0

    def load_batch(self, items: Iterable[CountryOut], batch_id: UUID) -> LoadResult:
        errors = []
        inserted = 0
        updated = 0
        for it in items:
            key = it.code or it.normalized_name
            existing = self.store.get(key)
            if existing:
                # simple update if different
                if existing["name"] != it.name:
                    existing["name"] = it.name
                    updated += 1
            else:
                self.store[key] = {"name": it.name, "code": it.code, "source_id": it.source_id}
                inserted += 1
        return LoadResult(inserted=inserted, updated=updated, errors=errors)

# Example usage in a test/demo:
def demo():
    rows = [
        CountryIn(mb_id=1, iso_code="US", name="United States", last_updated=datetime(2020,1,1)),
        CountryIn(mb_id=2, iso_code="GB", name="United Kingdom", last_updated=datetime(2020,1,2)),
    ]
    extractor = InMemoryCountryExtractor(rows)
    translator = CountryTranslator()
    loader = InMemoryLoader()
    orch = Orchestrator(extractor, translator, loader, batch_size=100)
    # simple persist_watermark_fn for demo: no-op that returns latest processed ts on read
    last = {"ts": None}
    def persist_watermark_fn(max_ts, batch_id, read_only=False):
        if read_only:
            return last["ts"]
        last["ts"] = max_ts
    orch.run_full_load(persist_watermark_fn)
    print("Store:", loader.store)