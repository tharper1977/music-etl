# python
\"\"\"
Composition root: only place where concrete adapters are instantiated and wired.
\"\"\"
from infra.config import load_config
from infra.logging import configure_logging
from adapters.postgres.connection import PostgresConnection
from adapters.postgres.repository import PostgresRepository
from adapters.sqlserver.connection import SQLServerConnection
from adapters.sqlserver.repository import SQLServerRepository
from adapters.mappers.musicbrainz_to_domain import MusicBrainzToDomainMapper
from application.services.etl_service import ETLService

def main():
    configure_logging()
    cfg = load_config()

    # instantiate adapters (concrete)
    pg_conn = PostgresConnection(cfg.postgres.dsn)
    src_repo = PostgresRepository(pg_conn)

    ss_conn = SQLServerConnection(cfg.sqlserver.conn_str)
    dst_repo = SQLServerRepository(ss_conn)

    mapper = MusicBrainzToDomainMapper()

    etl = ETLService(src_repo, dst_repo, mapper, batch_size=500)
    etl.run_full_load()

if __name__ == '__main__':
    main()
