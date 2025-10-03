
## Objective
Define a pragmatic, phased plan to build the ETL that moves a curated subset of MusicBrainz (Postgres) into MusicCollection (SQL Server) using the onion/ports-adapters design, preserving MusicCollection as the canonical user-facing database and avoiding destination schema changes.

---

## Principles
- Keep MusicCollection authoritative; do not change its schema.
- Persist source→destination mappings in MusicCollection.Identifier for deterministic idempotency (recommended).
- Load reference (lookup) data first to meet referential integrity.
- Use staging tables + set-based MERGE upserts for performance and durability.
- Surface ambiguous matches for human review; avoid automated risky merges.
- Implement small, well-tested increments — verify before expanding scope.

---

## Phases (high level)

Phase 0 — Project setup (1 day)
- Initialize repo structure (src/, tools/, scripts/, docs/).
- Add basic scaffolding following onion architecture (core, application, adapters, infra).
- Add linters and architecture import check script to CI.
- Add README.md and CONTRIBUTING.md with architectural rules.

Phase 1 — Reference data ETL (2–3 days)
- Implement extraction for lookup values from MB: Country/Area, ArtistType, Genre/Tag, Label, MediumFormat, Website.
- Create staging DDL for each lookup in MC (staging schema).
- Implement Python ETL job to:
  - Extract distinct lookup values,
  - Normalize strings,
  - Bulk load into staging,
  - MERGE into MC lookup tables,
  - Cache lookup IDs for subsequent runs.
- Add unit tests and an integration test against small sample.

Phase 2 — Artist ETL (3–5 days)
- Design Artist staging DDL.
- Implement mappers: MB artist row -> Domain Artist -> Destination Artist shape.
- Implement ETL orchestration:
  - Extract batch from MB with server-side cursor,
  - Transform and bulk-load staging.Artist,
  - Resolve lookups via staging -> MERGE into MC.Artist using Identifier-first then natural-key matching,
  - Insert Identifier mappings for new or newly-linked rows,
  - Record ambiguous matches to review table.
- Add tests (unit & integration) and run smoke load on sample data.

Phase 3 — Recording & Track ETL (3–6 days)
- Implement recording staging and mapping; resolve PrimaryArtist via Identifier lookups.
- Implement track staging, mapping to Disc/Recording and MERGE logic.
- Handle ISRC uniqueness and exceptions.
- Test end-to-end for a set of artists and their recordings/tracks.

Phase 4 — Albums / Editions / Discs (4–7 days)
- Define mapping policy: ReleaseGroup -> Album, Release -> Edition.
- Implement extraction and transformation for releases, editions, discs.
- Upsert Albums and Editions; create relationships and identifiers.
- Handle catalog numbers, release dates and ambiguity.

Phase 5 — Relationships & Junctions (3–5 days)
- Implement ArtistGenre, AlbumGenre, TrackGenre, Credit, ArtistMembership ETLs.
- Use set-based inserts with dedupe; ensure referential integrity by mapping parent IDs first.

Phase 6 — Ambiguity Review UI / Process (2–4 days)
- Provide a simple CSV export and/or a minimal web UI for human reviewers to accept/reject ambiguous mappings.
- Implement a process to apply review decisions to Identifier table and re-run ETL for resolved rows.

Phase 7 — Incremental sync, watermarking & scheduling (2–3 days)
- Add MC.ETLWatermark and MC.ETLRun tables.
- Implement incremental extract logic using last_updated watermark from MB.
- Schedule as a cron or Windows scheduled task; implement retry logic and backoff for transient errors.

Phase 8 — Performance tuning, production readiness (ongoing)
- Tune batch sizes and bulk-load mechanisms.
- Consider index maintenance for initial large loads.
- Harden logging/monitoring and add metrics.
- Add end-to-end integration tests and CI jobs.

---

## Detailed technical tasks

1. Composition root & DI
- Single composition script to wire adapters (Postgres repo, SQLServer repo) into application services.
- Avoid importing adapters in core or application layers.

2. Ports & interfaces
- Core Protocols: SourceRepository, DestinationRepository, Mapper.
- Application: ETLService orchestrates extract/transform/load per entity.

3. Adapters
- Postgres adapter: use psycopg3 with named cursor to stream large result sets.
- SQL Server adapter: use pyodbc with fast_executemany for bulk inserts or use BULK INSERT for CSV staging.
- Mapper adapters: MusicBrainz -> Domain, Domain -> Destination.

4. Staging tables
- Create staging schema in MC (MusicCollection.staging or similar).
- Design staging columns to mirror destination insert columns plus source_id (MB integer), source_last_updated, batch_id.

5. Upsert strategy
- MERGE into target with matching priority:
  a) Identifier join (Source='MusicBrainz', Value=MB_id)
  b) Natural-key match (destination uniqueness)
  c) INSERT if no match
- Insert Identifier for new rows (and optionally for matched rows lacking an Identifier).

6. Matching & normalization
- Implement deterministic normalization functions: trim, lower, collapse spaces, strip diacritics optionally.
- Implement fuzzy match module with configurable thresholds; store candidate matches for review.

7. Error handling and quarantining
- Quarantine failing rows with error details and batch id.
- Provide operators a retry path after fixes.

8. Watermarks and idempotency
- Store last processed MB source timestamps by entity in MC.ETLWatermark.
- ETL extracts rows WHERE last_updated > watermark.

9. Logging & metrics
- Structured logs: batch_id, entity, rows_extracted, rows_inserted, rows_updated, errors.
- Emit metrics suitable for Prometheus / logs aggregation (optional).

---

## Data quality & validation rules
- All inserted rows must satisfy MC constraints; ETL must validate and normalize before load.
- Duplicates detection: ensure no violation of unique indexes after MERGE.
- Referential integrity checks: verify foreign keys are resolvable for every inserted entity.
- Produce summary report for each batch and store in MC.ETLRun.

---

## Risk mitigation & notes
- Risk: False merges — mitigate via conservative matching, thresholding and human review.
- Risk: Race conditions with parallel ETL writes — prefer single writer or partitioned concurrency with careful lock/use of UPSERT semantics.
- Risk: Performance issues — use staging + bulk operations and tune batch size.
- Maintain idempotency by storing mappings (Identifier) and using watermarks.

---

## Deliverables for first sprint (2 weeks)
- Repo skeleton and CI import-check.
- Staging DDL for lookup + Artist.
- Python ETL job for Lookups (U01) and Artist (U02) end-to-end with tests.
- MERGE SQL template for Artist upsert and Identifier writes.
- check_imports tool in CI to enforce architecture.
- Small sample dataset and integration test instructions.

---

## Success criteria (for initial release)
- Reference data loaded and stable in MC.
- A sample set of ~100 artists from MB imported to MC with correct FKs and no uniqueness violations.
- Identifier mappings created for imported entities.
- Ambiguous matches flagged and review pipeline working.
- CI tests cover mappers and a small end-to-end integration.

---

## Next immediate actions (what I can produce now)
- Generate staging DDL and MERGE template for Artist.
- Produce Python ETL scaffold for Lookups + Artist (with psycopg3 + pyodbc placeholders).
- Create fuzzy-match utility module and unit tests.
- Add a GitHub Actions workflow example to run import-checks and tests.

Which of these immediate artifacts would you like me to generate first?