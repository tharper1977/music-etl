# python
from typing import Dict, Any, Protocol
from core.models import Artist

class Mapper(Protocol):
    def map_source_artist_to_domain(self, row: Dict[str, Any]) -> Artist:
        ...
    def map_artist_to_destination(self, artist: Artist) -> Dict[str, Any]:
        ...
