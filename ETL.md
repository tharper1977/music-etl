# Music ETL Plan: EF-Core-Based Extraction

This document describes an ETL approach for extracting and staging music metadata (Artists, Albums, Editions, Discs, Tracks, etc.) using Entity Framework Core entity maps and navigation properties, keeping native SQL use to a minimum and maximizing maintainability and type safety.

---

## Guiding Principles

- **Use Entity Framework entity types, navigation properties, and configurations to extract data.**
- **Avoid magic SQL strings where possible.** Prefer LINQ with projection or includes, leveraging the entity graph.
- **Separate extraction by domain:** Artists, Albums, Editions, Discs, and Tracks each have their own extraction job, ideally parallelizable.
- **Output normalized, joinable datasets for downstream jobs (T and L steps).**
- **Batches/page-through when possible to support large datasets.**
- **Only use raw SQL for corner-case calculations that cannot be expressed in LINQ or on a mapped view.**

---

## 1. Artist Extraction

**Goal:** Extract all core artist info, aliases, genres, relationships, and relevant metadata.

- Query `DbContext.Artists`
- For each artist, include:
    - Genres (`.Include(a => a.Genres)`)
    - Aliases
    - Relationships (e.g., links to other entities)
- Project to a flat DTO for staging or write directly to the staging system.

```
var artists = await dbContext.Artists
.Include(a => a.Genres)
.Include(a => a.Aliases)
//.Include(a => a.Relationships) // as needed
.ToListAsync();
```

---

## 2. Album/Release Extraction

**Goal:** Extract all albums (release_groups), including mapping to primary artists and summary metadata.

- Query `DbContext.Albums`
- Include:
    - PrimaryArtist (navigation)
    - Editions (if needed for album-level denormalization)
- Use projection to select only required staging columns.

```
var albums = await dbContext.Albums
.Include(a => a.PrimaryArtist)
.ToListAsync();
```

---

## 3. Edition Extraction

**Goal:** Extract all editions/releases for each album.

- Query `DbContext.Editions`
- Include:
    - Album (navigation)
    - Labels
    - Discs (if needed for edition-level flattening)
- Filter or batch as needed for large scale.

```
var editions = await dbContext.Editions
.Include(e => e.Album)
.Include(e => e.Labels)
.Include(e => e.Discs)
.ToListAsync();
```

---

## 4. Disc Extraction

**Goal:** Extract all disc/medium data, linked to editions.

- Query `DbContext.Discs`
- Include:
    - Edition
    - Tracks (optional, or handled in a later job for scalability)
- Filter/batch as needed.

```
var discs = await dbContext.Discs
.Include(d => d.Edition)
.Include(d => d.Tracks)
.ToListAsync();
```

---

## 5. Track Extraction

**Goal:** Extract all tracks/songs, including minimal joining where possible.

- Query `DbContext.Tracks`
- Include:
    - Disc
    - (Optionally) Artist credit
- Batch/paginate as needed.

```
var tracks = await dbContext.Tracks
.Include(t => t.Disc)
//.Include(t => t.ArtistCredit)
.ToListAsync();
```

---

## 6. Job Orchestration

- Each job runs independently, can be run in parallel, and outputs its result to downstream staging (files, database, queues, etc.).
- Jobs can share context or communicate IDs as needed for filtered extractions.
- Use an orchestration system (e.g., Hangfire, custom background services, distributed queue) for reliability and scaling.
- Monitor job metrics for bottlenecks and tune includes/projection depth accordingly.

---

## 7. Performance & Maintenance Notes

- Use `.AsNoTracking()` for extractors to maximize read throughput (no change tracking needed).
- Consider DTO projection via `.Select()` to control output shape and minimize in-memory graph size.
- For enormous cardinalities, partition by Id ranges or creation date.
- If certain queries become slow and cannot be sensibly expressed in EF, fall back to a well-documented raw SQL “view” or SQL projection, but keep this as an exception.

---

## 8. Summary Table

| Extraction | Source Entity/Map | Navigations to Include           | Comments                        |
|------------|------------------|----------------------------------|---------------------------------|
| Artists    | Artist           | Genres, Aliases, Relationships   | Fully parallelizable            |
| Albums     | Album            | PrimaryArtist, Editions          | Split if scope is large         |
| Editions   | Edition          | Album, Labels, Discs             | May skip Discs for perf         |
| Discs      | Disc             | Edition, Tracks                  | Can skip Tracks for perf        |
| Tracks     | Track            | Disc, ArtistCredit (optional)    | Partition for scale             |

---

## 9. Extension Points

- Add extraction for supplemental or reference tables (e.g., genres, labels) as needed.
- Extend entity configurations as new fields or relationships become important for analytics.

---