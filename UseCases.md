## Purpose
Describe the concrete use cases required to transfer a selected subset of MusicBrainz (source) data into the MusicCollection (destination) database while preserving MusicCollection as the canonical user-facing store and without changing the destination schema (other than relying on its identity PKs). The ETL must be idempotent, respect referential integrity, and surface ambiguous matches for review.

---

## Actors
- ETL Operator (automation or scheduled job)
- ETL Pipeline (Python application)
- Database Systems
  - Source: MusicBrainz (Postgres)
  - Destination: MusicCollection (SQL Server)
- Human Reviewer (for ambiguous match resolution)
- CI / Monitoring systems (logs, metrics)

---

## Global Assumptions
- MusicBrainz UUIDs are not used as persistent keys; MB integer IDs may be used transiently inside the ETL.
- MusicCollection schema is authoritative and must not be altered.
- The MusicCollection.Identifier table will be used to persist source → destination mappings (optional but recommended for idempotency).
- Reference (lookup) tables must be loaded first to satisfy destination FKs.
- ETL operates in batches and supports incremental runs via watermarks.

---

## High-Level Use Cases

### 1. U01 — Load Reference Data (Lookup tables)
Purpose: Ensure Country, ArtistType, Genre, Label, MediumFormat, Tag, Website tables in MC are populated/upserted before dependent entities run.

Preconditions:
- Valid connection to source & destination.
- Staging schema/tables available on destination.

Main flow:
1. Extract distinct lookup values from MB (e.g., area/country, artist_type, tag).
2. Normalize values (trim, case, collapse whitespace, normalize diacritics if used).
3. Bulk-load into destination staging table.
4. Upsert into MC lookup tables using set-based MERGE on natural keys (Name or CountryCode).
5. Cache returned IDs for ETL process.

Postconditions:
- Lookup tables contain required values.
- Lookup ID cache populated for subsequent steps.

Errors & recovery:
- On constraint errors, write failing rows to quarantine and log; continue with other lookups.

---

### 2. U02 — Map & Upsert Artists
Purpose: Import MB artists into MC.Artist, preserving referential link to Country and ArtistType, and creating a mapping entry in Identifier.

Preconditions:
- Lookup tables loaded (U01).
- Staging.Artist table exists in MC.

Main flow:
1. Extract a batch of MB artists (with relevant fields: MB integer id, name, sort_name, country/code, type, begin_year, disambiguation).
2. Transform source row -> normalized destination shape (map country code -> CountryId via cache; map artist type -> ArtistTypeId).
3. Write transformed rows to staging.Artist.
4. In a single DB transaction:
   a. For each staging row, attempt match by:
      i. Identifier (Source='MusicBrainz', Value=MB_id) → target ArtistId
      ii. Else natural unique key (Name, CountryId, IsGroup) → target ArtistId
      iii. Else perform INSERT into MC.Artist
   b. For newly inserted rows, insert Identifier row mapping MB_id -> new ArtistId.
   c. For matched rows without Identifier, optionally insert Identifier linking MB_id -> existing ArtistId.
5. Commit transaction.

Postconditions:
- MC.Artist updated/inserted deterministically.
- Identifier entries created for MB->MC mapping.

Ambiguity handling:
- If natural-key match is weak (Country NULL, many candidates, etc.), flag row and write candidate matches to staging.ETLReview for manual resolution. Do not auto-merge ambiguous rows.

Errors & recovery:
- On error, rollback transaction; write batch to failure staging for retry and diagnostics.

---

### 3. U03 — Map & Upsert Recording (and Recording-level Identifiers)
Purpose: Import MB recordings and resolve PrimaryArtist FK to MC.Artist.

Preconditions:
- U02 completed for the relevant artists.
- Recording staging table exists.

Main flow:
1. Extract MB recordings with duration, ISRC, artist credit reference.
2. Transform: map PrimaryArtist via Identifier lookup (MB artist id -> MC ArtistId) or by matching logic if Identifier absent.
3. Load to staging.Recording and perform MERGE into MC.Recording:
   - Match by Identifier (if present) or ISRC (unique) or by name + PrimaryArtistId.
4. Insert Identifier mapping for MB recording id -> MC.RecordingId when new.

Edge cases:
- If ISRC exists and maps to a different recording, flag for review.

---

### 4. U04 — Map Releases → Albums / Editions / Discs
Purpose: Map MB ReleaseGroup → MC.Album and Release → MC.Edition / Disc.

Preconditions:
- U01, U02, U03 completed for related entities.

Main flow:
1. Extract ReleaseGroup and Release data from MB (with artist credits, release date, barcode).
2. Decide mapping policy (recommended):
   - MB ReleaseGroup → MC.Album
   - MB Release → MC.Edition
3. Transform and map PrimaryArtist via Identifier or match.
4. Upsert Album (MERGE by Identifier or Name + PrimaryArtist).
5. Upsert Edition and Disc and insert Identifier mappings as appropriate.

Ambiguity handling:
- If multiple MB ReleaseGroups map to same album natural key, flag for review.

---

### 5. U05 — Map & Upsert Tracks
Purpose: Create MC.Track rows from MB medium/track relations, link to MC.Disc and MC.Recording.

Preconditions:
- Editions/Discs and Recordings exist (U03, U04).

Main flow:
1. Extract MB track rows (title, position, track_number, duration, recording_id).
2. Transform: resolve DiscId (via Edition+DiscNumber), resolve RecordingId (Identifier or match by title+artist).
3. Load to staging.Track; MERGE into MC.Track using match rules:
   - match by Identifier
   - else by (DiscId, TrackNumber) or (DiscId, Position)
4. For inserts, create Identifier mapping.

Edge cases:
- Tracks with missing recording_id: insert track with NULL RecordingId and flag for later reconciliation.

---

### 6. U06 — Map Many-to-Many / Junctions (Genres, Credits, Memberships)
Purpose: Populate MC.ArtistGenre, AlbumGenre, TrackGenre, Credit, ArtistMembership from MB relations.

Preconditions:
- Core entities (Artist, Album, Track, Genre) upserted.

Main flow:
1. Extract relationship sets from MB for a batch of parent entities.
2. Transform parent/child MB IDs to MC IDs using Identifier table or resolved matches.
3. Insert deduplicated junction rows using INSERT ... WHERE NOT EXISTS or MERGE into junction tables.

Notes:
- Handle sequence/order and IsPrimary flags for credits.
- For deletions or sync behavior, decide whether to replace relationships or incrementally upsert.

---

### 7. U07 — Watermarking & Incremental Sync
Purpose: Enable incremental updates from MB source.

Preconditions:
- All entity ETLs able to accept a since_timestamp or last_id watermark.

Main flow:
1. Maintain MC.ETLWatermark table (EntityName, LastSourceUpdated, LastBatchId).
2. On each run, extract MB rows WHERE last_updated > LastSourceUpdated (or use MB change tables if available).
3. Run ETL pipelines for changed entities in dependency order.
4. On successful commit, update watermark to max(last_updated) processed.

Notes:
- For initial full-load, use bootstrapping logic: load all reference tables then bulk-load entities with larger batch sizes and index maintenance strategy.

---

### 8. U08 — Ambiguity Review & Manual Resolution
Purpose: Provide a process for human review of ambiguous matches and apply decisions to mapping.

Main flow:
1. ETL writes ambiguous candidates to staging.ETLReview with context and match scores.
2. Human reviewer inspects CSV or UI; selects mapping or requests manual creation.
3. Reviewer action either:
   - approves a specific MC entity mapping → ETL inserts Identifier (MB_id -> MC_Id) into Identifier table,
   - requests creation → create MC row and Identifier,
   - marks as no-match → ETL will insert new MC row when reprocessed.
4. ETL picks up review decisions and proceeds.

---

### 9. U09 — Error Handling, Quarantine & Retry
Purpose: Ensure failed rows are quarantined and retried safely.

Main flow:
1. On transformation or load error, move offending rows to staging.Quarantine with error details and batch_id.
2. Notify operator/monitoring with details.
3. Provide a retry mechanism that reprocesses quarantine rows after fixes.

---

### 10. U10 — Validation & Data Quality Checks
Purpose: Verify ETL correctness and detect problematic mappings.

Checks (examples):
- Referential integrity: all FK columns are non-null where required and refer to existing IDs.
- Duplicate detection: ensure ETL did not create duplicate MC rows against uniqueness constraints.
- Match consistency: MB_id always maps to at most one MC entity per EntityType.
- Sampling checks: randomly verify sample MB → MC mappings for accuracy.

Outputs:
- Summary metrics (rows extracted, inserted, updated, errors).
- Detailed logs and sample failure rows.

---

## Cross-Cutting Use Cases

### C01 — Batch Size Tuning & Performance
- Tune batch size based on destination performance; default start: 500–2000 rows.
- Bulk-load staging, then set-based MERGE operations.

### C02 — Concurrency Control
- Single-writer ETL recommended.
- If parallelizing, partition source sets so workers do not contend for same natural keys or mapping writes. Use database locks or UPSERT semantics to avoid race conditions.

### C03 — Monitoring & Observability
- Emit metrics: extracted_count, inserted_count, updated_count, failure_count, avg_latency.
- Structured logs with batch_id and entity type for traceability.

### C04 — CI & Tests
- Unit tests for mappers and matching logic.
- Integration tests with small dataset for each major entity.
- A CI job that runs the architecture import-check and unit/integration smoke tests.

---

## Matching Strategy Summary (for name fields)
1. Use Identifier mapping if present.
2. Exact match on natural unique keys (MC unique indexes).
3. Normalized exact match (trim, lower, collapse spaces, remove diacritics optionally).
4. Deterministic heuristics: require match on additional attributes when country is null.
5. Fuzzy match with threshold and manual review for mid-scoring cases.
6. If still no match and it doesn't violate unique constraints, create new MC row and insert Identifier.

---

## Transactions & Atomicity
- Perform upsert sequences per-batch inside a transaction to avoid partial mapping states.
- Keep transactions short to minimize locks.
- For large initial loads, consider chunked transactions and index maintenance.

---

## Logging & Auditing
- Persist ETL run metadata (start_time, end_time, batch_id, source_range, rows_processed) in MC.ETLRun table.
- Record each mapping decision (auto vs manual) for auditability.

---

## Suggested Minimal Deliverables (first iteration)
- Staging DDL for Lookup + Artist + Recording + Track.
- Python ETL script for:
  - Lookup load (U01)
  - Artist ETL (U02) end-to-end with Identifier write and review logging
- MERGE SQL template for Artist upsert using Identifier-first then natural-key match.
- check_imports.py style architecture guard + tests.
- Sample dataset (10–100 rows) and integration test.

---

## Next Actions
- Confirm whether to persist MB integer IDs in MusicCollection.Identifier.Value (recommended for idempotency).
- I can produce the UseCase.md file as an actual file scaffold or generate the Artist ETL artifacts (staging DDL, Python, MERGE) next. Which would you like?

