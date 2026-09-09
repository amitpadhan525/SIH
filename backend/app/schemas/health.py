from typing import Optional
from pydantic import BaseModel

class HealthResponse(BaseModel):
    status: str
    service: str

class DBHealthResponse(BaseModel):
    database: str
    detail: Optional[str] = None
