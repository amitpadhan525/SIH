from datetime import datetime
from decimal import Decimal
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator
from backend.app.schemas.product_image import ProductImageRead

ALLOWED_PRODUCT_STATUSES = {"draft", "published", "archived"}

class ProductBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255, description="Name of the product")
    category: str = Field(..., min_length=1, max_length=100, description="Product category")
    description: Optional[str] = Field(default=None, description="Detailed product description")
    material: Optional[str] = Field(default=None, max_length=100, description="Primary material used")
    price: Optional[Decimal] = Field(default=None, ge=0, description="Price in INR")
    status: str = Field(default="draft", max_length=50, description="Product status: draft, published, archived")

    @field_validator("name", "category")
    @classmethod
    def validate_non_empty_strings(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("Field cannot be empty or only whitespace")
        return stripped

    @field_validator("status")
    @classmethod
    def validate_status(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in ALLOWED_PRODUCT_STATUSES:
            raise ValueError(f"Status must be one of: {', '.join(sorted(ALLOWED_PRODUCT_STATUSES))}")
        return normalized


class ProductCreate(ProductBase):
    artisan_id: int = Field(..., description="Foreign key referencing artisans.id")


class ProductUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=255)
    category: Optional[str] = Field(default=None, min_length=1, max_length=100)
    description: Optional[str] = Field(default=None)
    material: Optional[str] = Field(default=None, max_length=100)
    price: Optional[Decimal] = Field(default=None, ge=0)
    status: Optional[str] = Field(default=None, max_length=50)

    @field_validator("name", "category")
    @classmethod
    def validate_non_empty_strings(cls, value: Optional[str]) -> Optional[str]:
        if value is not None:
            stripped = value.strip()
            if not stripped:
                raise ValueError("Field cannot be empty or only whitespace")
            return stripped
        return value

    @field_validator("status")
    @classmethod
    def validate_status(cls, value: Optional[str]) -> Optional[str]:
        if value is not None:
            normalized = value.strip().lower()
            if normalized not in ALLOWED_PRODUCT_STATUSES:
                raise ValueError(f"Status must be one of: {', '.join(sorted(ALLOWED_PRODUCT_STATUSES))}")
            return normalized
        return value


class ProductRead(ProductBase):
    id: int
    artisan_id: int
    created_at: datetime
    updated_at: datetime
    images: List[ProductImageRead] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)
