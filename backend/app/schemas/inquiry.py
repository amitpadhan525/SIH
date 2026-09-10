from datetime import datetime
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, ConfigDict, EmailStr, Field


class InquiryBase(BaseModel):
    buyer_name: str = Field(..., min_length=2, max_length=255)
    buyer_email: str = Field(..., min_length=5, max_length=255, pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
    buyer_phone: str = Field(..., min_length=5, max_length=50)
    buyer_type: str = Field(default="wholesale_b2b", description="'retail', 'wholesale_b2b', 'export', 'institutional'")
    quantity: int = Field(default=1, ge=1)
    target_price: Optional[Decimal] = Field(default=None, ge=0)
    message: Optional[str] = Field(default=None)


class InquiryCreate(InquiryBase):
    pass


class InquiryStatusUpdate(BaseModel):
    status: str = Field(..., description="'pending', 'contacted', 'accepted', 'declined'")


class InquiryRead(InquiryBase):
    id: int
    product_id: int
    status: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ArtisanInquiryRead(InquiryRead):
    product_name: str
    product_price: Optional[Decimal] = None
    product_image_url: Optional[str] = None
