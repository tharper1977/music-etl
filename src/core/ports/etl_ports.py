# python
# file: src/core/ports/etl_ports.py

from __future__ import annotations
from typing import Iterable, Protocol, TypeVar, Generic, Optional
from datetime import datetime
from dataclasses import dataclass
from uuid import UUID

TIn = TypeVar("TIn")
TOut = TypeVar("TOut")

@dataclass
class ExtractedRow:
    source_id: Optional[str]
    payload: dict
    source_updated_at: Optional[datetime] = None

@dataclass
class LoadResult:
    inserted: int
    updated: int
    errors: list[dict]

class Extractor(Protocol[TIn]):
    def extract_batch(self, since: Optional[datetime], limit: int) -> Iterable[TIn]:
        """Return an iterable of TIn records from source."""
        ...

class Translator(Protocol[TIn, TOut]):
    def translate(self, item: TIn) -> TOut:
        """Map a single TIn to TOut (destination-shaped)."""
        ...

    def translate_batch(self, items: Iterable[TIn]) -> list[TOut]:
        """Optional batch translation (default: map translate over items)."""
        ...

class Loader(Protocol[TOut]):
    def load_batch(self, items: Iterable[TOut], batch_id: UUID) -> LoadResult:
        """Load TOut items (staging + upsert) and return LoadResult."""
        ...
