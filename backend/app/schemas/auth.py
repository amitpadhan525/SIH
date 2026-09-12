from typing import Optional
from pydantic import BaseModel, Field


class UserRegisterRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    phone: str = Field(..., min_length=1, max_length=32)
    password: Optional[str] = Field(default=None, max_length=128)
    role: str = Field(default="artisan", description="'artisan', 'buyer', 'admin'")
    language: str = Field(default="hi", description="'hi', 'or', 'bn', 'en'")
    location: Optional[str] = Field(default=None)
    craft_type: Optional[str] = Field(default=None, description="Required for artisans")


class UserLoginRequest(BaseModel):
    phone: str = Field(..., min_length=1, max_length=32)
    password: str = Field(..., min_length=4)


class OtpSendRequest(BaseModel):
    phone: str = Field(..., min_length=1, max_length=32)


class OtpSendResponse(BaseModel):
    phone: str
    message: str
    demo_otp: Optional[str] = Field(default=None, description="Simulated 6-digit OTP for testing without live SMS gateway cost")


class OtpVerifyRequest(BaseModel):
    phone: str = Field(..., min_length=1, max_length=32)
    otp: str = Field(..., min_length=4, max_length=8)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    artisan_id: Optional[int] = None
    name: str
    role: str
    phone: str
    is_profile_complete: bool = False
    craft_category: Optional[str] = None
    state: Optional[str] = None
    district: Optional[str] = None
    preferred_language: Optional[str] = "hi"
    artisan_name: Optional[str] = None
    artisan_type: Optional[str] = None
    experience_years: Optional[int] = None
    description: Optional[str] = None
