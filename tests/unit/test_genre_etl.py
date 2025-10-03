# python
# File: tests/unit/test_genre_etl.py
from __future__ import annotations
from datetime import datetime
from uuid import UUID

from application.services.orchestrator import Orchestrator
from .conftest import MockGenreExtractor, MockGenreTranslator, MockGenreLoader, GenreIn, GenreOut

def test_genre_orchestrator_full_load(sample_genres):
    extractor = MockGenreExtractor(sample_genres)
    translator = MockGenreTranslator()
    loader = MockGenreLoader()
    orch = Orchestrator[GenreIn, GenreOut](extractor, translator, loader, batch_size=100)

    # simple watermark persistence function that stores last ts in closure
    watermark = {"ts": None}
    def persist_watermark_fn(max_ts: datetime | None, batch_id: UUID | None, read_only: bool = False):
        if read_only:
            return watermark["ts"]
        watermark["ts"] = max_ts
        return watermark["ts"]

    orch.run_full_load(persist_watermark_fn)

    # After run, loader.store should contain normalized genre keys
    store = loader.store
    assert "rock" in store
    assert "progressive rock" in store
    assert "electronic" in store

    # inserted count should match number of distinct normalized genres
    assert len(store) == 3
    # watermark should be updated to the last genre source_updated_at
    assert watermark["ts"] == max(g.last_updated for g in sample_genres)

def test_genre_upsert_updates_existing(sample_genres):
    # create initial store with 'rock' already present but older name
    extractor = MockGenreExtractor(sample_genres)
    translator = MockGenreTranslator()
    loader = MockGenreLoader()
    # pre-populate loader store with a slightly different representation to force update
    loader.store["rock"] = {"name": "ROCK OLD", "source_id": "999", "updated_at": datetime(2019, 1, 1)}

    orch = Orchestrator[GenreIn, GenreOut](extractor, translator, loader, batch_size=100)

    watermark = {"ts": None}
    def persist_watermark_fn(max_ts, batch_id, read_only=False):
        if read_only:
            return watermark["ts"]
        watermark["ts"] = max_ts
        return watermark["ts"]

    orch.run_full_load(persist_watermark_fn)

    # 'rock' should exist and have been updated to canonical capitalization from translator
    assert loader.store["rock"]["name"] == "Rock"
    # other genres still inserted
    assert "progressive rock" in loader.store
    assert "electronic" in loader.store
