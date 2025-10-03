|text
# ReferenceDataProcess.md

## Purpose
Define the process, components, and orchestration pattern for moving reference (lookup) data from MusicBrainz (Postgres) into MusicCollection (SQL Server). The design uses a generic orchestrator pattern with |TIn, TOut| so the same pipeline skeleton can be reused for different lookup entities (Country, ArtistType, Genre, Label, MediumFormat, Tag, Website).

---

## High-level pattern (generic)
We implement a generic pipeline composed of three roles:
- Extractor: reads source rows and emits them in |TIn| format.
- Translator: converts |TIn| -> |TOut| (destination-shaped rows), performs normalization and light enrichment.
- Loader: takes |TOut| rows, writes to a staging table, and performs set-based upsert (MERGE) into the destination lookup table.

A lightweight generic orchestrator coordinates these components for each entity type:
- Orchestrator|TIn, TOut|:
  - iterate extract batches
  - translate each item
  - bulk write to staging
  - call loader to upsert/stabilize
  - commit and advance watermark
  - collect metrics and handle retries/errors

---

## Components & responsibilities

### Orchestrator|TIn, TOut|
Responsibilities:
- Accept configured Extractor, Translator, Loader instances for the entity.
- Manage batch loop, batch size, and concurrency (usually single-threaded for lookups).
- Maintain batch_id and source watermark handling.
- Provide hooks for pre/post hooks (e.g., pre-load lookups, post-load cache refresh).
- Emit structured metrics and logs for each batch.

Behavior outline:
- Get watermark (last_processed) for entity.
- Loop:
  - extractor.extract_batch(since=watermark, limit=batch_size) -> list|TIn|
  - translator.map_batch(list|TIn|) -> list|TOut|
  - loader.load_batch(list|TOut|, batch_id)
  - on success update watermark to max(source_ts) of processed rows
  - break when no rows returned

### Extractor
Responsibilities:
- Query MusicBrainz for distinct lookup values or changed rows using server-side cursor for large results.
- Return raw rows or a small structured DTO in |TIn| shape (keep it DB-agnostic).
- Provide extract_batch(since, limit) method.

Notes:
- For lookups we usually extract distinct values (SELECT DISTINCT ...).
- Use named cursors on Postgres to stream.

### Translator
Responsibilities:
- Convert |TIn| -> |TOut|.
- Normalize fields (trim, lower-case, collapse whitespace, remove diacritics if desired).
- Validate/clean values (lengths, null-handling).
- Optionally add provenance fields (source_id, source_value, source_updated_at).
- Compute natural-key values used by upsert logic (e.g., Name, CountryCode).

### Loader
Responsibilities:
- Receive list|TOut| and perform:
  1. Bulk insert into staging table (fast path: pyodbc fast_executemany, BULK INSERT, or bcp).
  2. Run set-based SQL to upsert from staging -> destination lookup table:
     - MERGE into target using natural-key (Name, Code)
     - OUTPUT inserted/updated ids for caching
  3. Optionally insert mapping into Identifier if policy requires
  4. Clean staging rows for succeeded batch (or keep for audit/quarantine)
- Return metrics (rows_inserted, rows_updated, conflicts, errors).

Notes:
- Use transactions per-batch to avoid partial state.
- Implement idempotent loaders: re-running same batch should not duplicate data.

---

## Staging schema (conceptual)
For each lookup entity, create a staging table under |MusicCollection.staging|:

Common columns:
- SourceId (nvarchar/nullable)  -- MB id as string (optional)
- Name (nvarchar)
- NormalizedName (nvarchar)     -- for matching convenience
- CountryCode / Code (char(2))  -- if applicable
- Additional fields (Description, Kind, etc.)
- SourceLastUpdated (datetime2)
- BatchId (uniqueidentifier)
- ExtractedAt (datetime2)

Rules:
- Staging is truncated/cleaned per batch or kept for audit depending on policy.
- Staging should be minimal and typed to match destination columns.

---

## Upsert strategy for lookups
- For lookups we match and upsert by strong natural key:
  - Country -> CountryCode or Name
  - ArtistType -> Name
  - Genre/Tag -> Name
  - Label -> Name + optionally Country
  - MediumFormat -> Name
- MERGE behavior:
  - WHEN MATCHED AND fields differ -> UPDATE (set Description, etc.)
  - WHEN NOT MATCHED BY TARGET -> INSERT
- Use an atomic MERGE in a transaction. Capture inserted IDs for caching.

Edge behaviors:
- If natural keys are ambiguous (rare for lookups), flag and move to review/quarantine.
- Make normalization consistent between lookup upsert SQL and Translator normalization.

---

## Matching & normalization rules (lookups)
- Always trim and collapse whitespace.
- Normalize to a canonical case (e.g., uppercase or lowercase) for comparison.
- Optionally strip diacritics for matching; preserve original for display.
- For Country: prefer ISO code matches; fallback to normalized Name if code missing.
- Use deterministic normalization functions in both Python translator and SQL MERGE (store NormalizedName in staging and compare).

---

## Caching & lookup resolution
- After loading lookups, the Loader returns mapping of (NaturalKey -> InsertedId).
- The Orchestrator should update an in-process cache (dictionary) for the ETL run to speed later entity processing.
- Cache invalidation: refresh after each successful batch or when loader returns changed IDs.

---

## Error handling & quarantine
- Loader should capture constraint violations or unexpected errors and insert problematic rows into staging.Quarantine with error details and batch_id.
- Orchestrator logs and continues with next batch or stops depending on error policy.
- Provide a retry tool that reprocesses rows from Quarantine after fixes.

---

## Watermarking & idempotency
- Loader or Orchestrator updates MC.ETLWatermark for the entity to the maximum SourceLastUpdated processed.
- Extraction uses watermark to perform incremental extracts.
- For idempotency, ensure staging + MERGE logic is deterministic and stable for replays of the same source rows.

---

## Observability & metrics
Per batch emit:
- batch_id, entity_name, start_time, end_time
- rows_extracted, rows_translated, rows_inserted, rows_updated, rows_error
- duration_ms
- sample of errors (first N)

Store run metadata in MC.ETLRun for auditing.

---

## Generic type signatures (pseudocode, pipe-masked)
- Orchestrator|TIn, TOut|:
  - constructor(extractor: Extractor|TIn|, translator: Translator|TIn, TOut|, loader: Loader|TOut|)
  - run_full_load(batch_size: int)
  - run_incremental(batch_size: int, since: datetime)

- Extractor|TIn|:
  - extract_batch(since: Optional[datetime], limit: int) -> Iterable|TIn|

- Translator|TIn, TOut|:
  - translate(item: TIn) -> TOut
  - translate_batch(items: Iterable|TIn|) -> List|TOut|

- Loader|TOut|:
  - load_batch(items: Iterable|TOut|, batch_id: UUID) -> LoadResult
  - LoadResult: { inserted_count, updated_count, errors: List }

---

## Example flow for Country (concrete)
1. Orchestrator obtains watermark for Country.
2. Extractor.query: SELECT iso_code, name, last_updated FROM area WHERE iso_code IS NOT NULL AND last_updated > :since
3. Translator.normalizes names, uppercases iso_code, prepares TOut rows.
4. Loader.bulk_insert_staging(staging.Country, rows, batch_id)
5. Loader.MERGE staging -> MusicCollection.music.Country on CountryCode or NormalizedName
6. Loader returns inserted/updated counts and mapping CountryCode -> CountryId
7. Orchestrator stores mapping to cache and updates watermark.

---

## Implementation notes & best practices
- Keep Translator logic deterministic and covered by unit tests (normalization rules).
- Keep Loader SQL in versioned SQL files and test MERGE statements on sample data locally.
- Use parameterized queries; avoid string concatenation in SQL to prevent injection.
- Use fast bulk insert methods appropriate for your environment (pyodbc fast_executemany or BCP).
- Keep staging table schemas and DDL under source control (folder: sql/staging).
- Add a small CLI per-entity for manual (re)load and to support QA.

---

## Deliverables for this reference-data process
- Generic Orchestrator class |TIn, TOut| (Python scaffold).
- Extractor implementations for each lookup (Country, ArtistType, Genre, Label, MediumFormat, Tag, Website).
- Translator implementations per lookup with unit tests for normalization.
- Loader implementation that:
  - creates/cleans staging table,
  - bulk-inserts rows,
  - performs MERGE into destination lookup table,
  - returns mapping IDs and metrics.
- Staging DDL scripts for each lookup entity.
- ETL run metadata scripts (MC.ETLRun, MC.ETLWatermark, staging.Quarantine).
- Sample dataset and integration test to validate the reference load end-to-end.

---

## Next steps I can produce
- A Python scaffold for the generic Orchestrator|TIn, TOut| and one complete entity flow for Country (Extractor, Translator, Loader, staging DDL, MERGE template, and unit tests).
- Or, produce the staging DDL and MERGE SQL templates for all lookup tables first.
Which would you like me to generate first?