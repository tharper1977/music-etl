# python
# file: src/application/services/orchestrator.py

from __future__ import annotations
from typing import Generic, TypeVar, Iterable, Optional
from datetime import datetime
from uuid import uuid4, UUID
import logging
from core.ports.etl_ports import Extractor, Translator, Loader, LoadResult, TIn, TOut

logger = logging.getLogger(__name__)

TIn = TypeVar("TIn")
TOut = TypeVar("TOut")

class Orchestrator(Generic[TIn, TOut]):
    """
    Generic ETL orchestrator for reference-data flows.

    Responsibilities:
    - drive extract -> translate -> load loop
    - manage batch ids and watermarks (caller persists watermark)
    - handle basic retries/errors per batch
    """

    def __init__(
        self,
        extractor: Extractor[TIn],
        translator: Translator[TIn, TOut],
        loader: Loader[TOut],
        batch_size: int = 1000,
        max_retries: int = 2,
    ) -> None:
        self.extractor = extractor
        self.translator = translator
        self.loader = loader
        self.batch_size = batch_size
        self.max_retries = max_retries

    def run_incremental(self, since: Optional[datetime], persist_watermark_fn) -> None:
        """
        Run incremental ETL starting from 'since'. persist_watermark_fn(max_ts, batch_id) should
        persist watermark and any metadata in the destination (DB).
        """
        batch_number = 0
        next_since = since
        while True:
            batch_number += 1
            batch_id = uuid4()
            logger.info("Starting batch %s (id=%s) since=%s", batch_number, batch_id, next_since)
            items = list(self.extractor.extract_batch(since=next_since, limit=self.batch_size))
            if not items:
                logger.info("No more rows to process; exiting.")
                break

            try:
                translated = self.translator.translate_batch(items)
            except Exception as ex:
                logger.exception("Translation failed for batch %s: %s", batch_id, ex)
                # optional: move items to quarantine via loader or external handler
                raise

            attempt = 0
            while True:
                attempt += 1
                try:
                    result: LoadResult = self.loader.load_batch(translated, batch_id)
                    logger.info(
                        "Loaded batch %s inserted=%d updated=%d errors=%d",
                        batch_id,
                        result.inserted,
                        result.updated,
                        len(result.errors),
                    )
                    # Derive watermark from translated payloads if present (caller policy)
                    max_ts = self._max_source_ts(translated)
                    persist_watermark_fn(max_ts, batch_id)
                    break
                except Exception as ex:
                    logger.exception("Load failed (attempt %d) for batch %s: %s", attempt, batch_id, ex)
                    if attempt > self.max_retries:
                        logger.error("Max retries reached for batch %s; aborting.", batch_id)
                        # move to quarantine or rethrow depending on policy
                        raise
                    logger.info("Retrying batch %s (attempt %d)...", batch_id, attempt + 1)

            # prepare for next loop: set since to last watermark persisted
            next_since = persist_watermark_fn(None, None, read_only=True)  # optional read-back hook
            # if persist_watermark_fn doesn't support read, caller must manage 'since' externally

    def run_full_load(self, persist_watermark_fn) -> None:
        """Convenience wrapper to run with no since watermark (full scan)."""
        self.run_incremental(since=None, persist_watermark_fn=persist_watermark_fn)

    @staticmethod
    def _max_source_ts(items: Iterable[TOut]) -> Optional[datetime]:
        """
        Attempt to derive maximum source timestamp from translated items.
        TOut implementations should include a 'source_updated_at' attribute or key in dict payload.
        """
        max_ts = None
        for it in items:
            ts = None
            if hasattr(it, "source_updated_at"):
                ts = getattr(it, "source_updated_at")
            elif isinstance(it, dict):
                ts = it.get("source_updated_at")
            if ts:
                if not max_ts or ts > max_ts:
                    max_ts = ts
        return max_ts