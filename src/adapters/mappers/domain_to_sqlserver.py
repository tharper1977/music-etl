# python
from typing import Dict, Any
from core.models import Artist

class DomainToSQLServerMapper:
    def map_artist(self, artist: Artist) -> Dict[str, Any]:
        # Convert domain model to destination row shape
        return {
            'mb_id': artist.id,
            'name': artist.name,
            'sort_name': artist.sort_name,
            'country': artist.country,
        }
