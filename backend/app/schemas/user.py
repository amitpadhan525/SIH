from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field

class UserBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255, description="Full name of the user")
    phone: str = Field(..., min_length=5, max_length=32, description="Unique phone number")
    role: str = Field(default="artisan", max_length=50, description="Role: artisan, buyer, admin")
    language: str = Field(default="en", max_length=20, description="Preferred language code")
    location: Optional[str] = Field(default=None, max_length=255, description="Geographic location / address")

class UserCreate(UserBase):
    pass

class UserUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=255)
    phone: Optional[str] = Field(default=None, min_length=5, max_length=32)
    role: Optional[str] = Field(default=None, max_length=50)
    language: Optional[str] = Field(default=None, max_length=20)
    location: Optional[str] = Field(default=None, max_length=255)

class UserRead(UserBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
