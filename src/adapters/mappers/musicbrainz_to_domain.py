# python
from typing import Dict, Any
from core.models import Artist
from core.ports.mapper import Mapper

class MusicBrainzToDomainMapper:
    def map_source_artist_to_domain(self, row: Dict[str, Any]) -> Artist:
        # Transform DB row dict to domain Artist
        return Artist(
            id=str(row.get('id')),
            name=row.get('name') or '',
            sort_name=row.get('sort_name'),
            country=row.get('country'),
        )

    # Not required here but implement to satisfy Mapper protocol in composition root if used directly
    def map_artist_to_destination(self, artist: Artist) -> Dict[str, Any]:
        return {
            'mb_id': artist.id,
            'name': artist.name,
            'sort_name': artist.sort_name,
            'country': artist.country,
        }
