# python
from dataclasses import dataclass
from typing import Optional

@dataclass
class Artist:
    id: str
    name: str
    sort_name: Optional[str] = None
    country: Optional[str] = None
