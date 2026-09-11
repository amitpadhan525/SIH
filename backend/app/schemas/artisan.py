from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field
from backend.app.schemas.user import UserRead


class ArtisanBase(BaseModel):
    craft_type: str = Field(default="Traditional Handicrafts", min_length=1, max_length=100, description="Type of craft or art form")
    craft_category: Optional[str] = Field(default=None, max_length=100, description="Category: Handloom, Pottery, etc.")
    artisan_name: Optional[str] = Field(default=None, max_length=255, description="Artisan or Business name")
    state: Optional[str] = Field(default=None, max_length=100, description="State / Province")
    district: Optional[str] = Field(default=None, max_length=100, description="District")
    preferred_language: str = Field(default="hi", max_length=50, description="Preferred language code or name")
    artisan_type: Optional[str] = Field(default=None, max_length=50, description="Individual, Self-help group, Cooperative, Small business")
    experience_years: Optional[int] = Field(default=None, ge=0, le=100, description="Years of experience (non-negative integer)")
    description: Optional[str] = Field(default=None, max_length=2000, description="Craft description / About the artisan")
    is_profile_complete: bool = Field(default=False, description="Whether mandatory onboarding fields are completed")


class ArtisanCreate(ArtisanBase):
    user_id: int = Field(..., description="Foreign key referencing users.id")


class ArtisanUpdate(BaseModel):
    craft_type: Optional[str] = Field(default=None, min_length=1, max_length=100)
    craft_category: Optional[str] = Field(default=None, max_length=100)
    artisan_name: Optional[str] = Field(default=None, max_length=255)
    state: Optional[str] = Field(default=None, max_length=100)
    district: Optional[str] = Field(default=None, max_length=100)
    preferred_language: Optional[str] = Field(default=None, max_length=50)
    artisan_type: Optional[str] = Field(default=None, max_length=50)
    experience_years: Optional[int] = Field(default=None, ge=0, le=100)
    description: Optional[str] = Field(default=None, max_length=2000)
    is_profile_complete: Optional[bool] = None


class ArtisanProfileUpdateRequest(BaseModel):
    full_name: str = Field(..., min_length=1, max_length=255, description="Artisan's personal full name")
    craft_category: str = Field(..., min_length=1, max_length=100, description="Craft category (e.g., Handloom, Pottery)")
    state: Optional[str] = Field(default=None, max_length=100, description="Optional State")
    district: Optional[str] = Field(default=None, max_length=100, description="Optional District")
    preferred_language: str = Field(default="Hindi", min_length=1, max_length=50, description="Preferred language (e.g., Odia, Hindi, English)")
    artisan_name: Optional[str] = Field(default=None, max_length=255, description="Optional Artisan / Business Brand Name")
    artisan_type: Optional[str] = Field(default=None, max_length=50, description="Optional Artisan type")
    experience_years: Optional[int] = Field(default=None, ge=0, le=100, description="Optional years of experience")
    description: Optional[str] = Field(default=None, max_length=2000, description="Optional craft description")



class ArtisanRead(ArtisanBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    user: Optional[UserRead] = None

    model_config = ConfigDict(from_attributes=True)
