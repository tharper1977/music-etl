# python
from typing import Iterable, Dict, Any, Protocol

class SourceRepository(Protocol):
    def fetch_artists_batch(self, offset: int, limit: int) -> Iterable[Dict[str, Any]]:
        \"\"\"Return raw rows (DB-specific dict) from source in batches.\"\"\"
        ...
