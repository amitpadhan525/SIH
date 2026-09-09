from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field
from backend.app.schemas.user import UserRead

class ArtisanBase(BaseModel):
    craft_type: str = Field(..., min_length=1, max_length=100, description="Type of craft or art form")

class ArtisanCreate(ArtisanBase):
    user_id: int = Field(..., description="Foreign key referencing users.id")

class ArtisanUpdate(BaseModel):
    craft_type: Optional[str] = Field(default=None, min_length=1, max_length=100)

class ArtisanRead(ArtisanBase):
    id: int
    user_id: int
    created_at: datetime
    user: Optional[UserRead] = None

    model_config = ConfigDict(from_attributes=True)
