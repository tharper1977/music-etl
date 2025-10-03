# python
from dataclasses import dataclass
import os

@dataclass
class PostgresConfig:
    dsn: str

@dataclass
class SQLServerConfig:
    conn_str: str

@dataclass
class Config:
    postgres: PostgresConfig
    sqlserver: SQLServerConfig

def load_config() -> Config:
    # Minimal loader - use env vars; extend to YAML or other config sources
    pg = PostgresConfig(dsn=os.environ.get('PG_DSN', 'postgresql://user:pass@localhost/musicbrainz'))
    ss = SQLServerConfig(conn_str=os.environ.get('MSSQL_CONN', 'Driver=...;Server=...;Database=...;UID=...;PWD=...'))
    return Config(postgres=pg, sqlserver=ss)
