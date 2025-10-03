# Project Outline: ETL (Python)

## Goals

- Connect to MusicBrainz database or dump
- Extract, transform, and load album, artist, and track data to SQL Server
- Automate ETL scheduling for syncs
- Provide logging and basic error handling
- Make jobs extensible for new datasets

## Milestones

1. **Connect to MB and SQL Server**
2. **Basic ETL for core entities**
3. **Error handling, logging, and config**
4. **Add unit tests and integration tests**
5. **Incremental or periodic updates**
6. **Documentation and onboarding guides**

## Task Outline

| Task                                      | Status  | Notes
|--------------------------------------------|---------|--------------------------|
| Set up Python environment                  | [ ]     |                          |
| MB → DataFrame extraction                  | [ ]     |                          |
| Album entity ETL                           | [ ]     |                          |
| Artist entity ETL                          | [ ]     |                          |
| Load into SQL Server                       | [ ]     | Use SQLAlchemy or pyodbc |
| Log, error-handling wrappers               | [ ]     |                          |
| Unit & e2e tests                           | [ ]     | pytest, unittest         |
| Doc + onboarding checklist                 | [ ]     |                          |

---

Future enhancements: incremental loads, REST hooks, metrics, and extensibility.
