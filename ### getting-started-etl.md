``` markdown
# Getting Started: Music ETL Project (Python)

## Setup

### Prerequisites

- Python 3.11 or newer
- Poetry (or pip)
- Access to MusicBrainz instance/database
- Access to target SQL Server database

### Quickstart

#### 1. Clone repository
```
bash git clone [REPO_URL] cd music-etl
``` 

#### 2. Install dependencies
```
bash poetry install
# OR
pip install -r requirements.txt
``` 

#### 3. Configure environment

- Copy `env.example` to `.env` and set credentials for MB and SQL Server.

#### 4. Run the ETL
```
bash poetry run python etl_main.py
# or
python etl_main.py
``` 

### Project structure

- `etl_main.py` — Entrypoint for the ETL job runner
- `/modules` — ETL steps (extract, transform, load)
- `/tests` — Unit/integration tests

---

See the `outline-etl.md` for roadmap and details.
```
