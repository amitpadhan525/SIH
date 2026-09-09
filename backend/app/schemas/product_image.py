from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field

class ProductImageBase(BaseModel):
    original_url: str = Field(..., max_length=1024, description="URL to the raw uploaded image")
    processed_url: Optional[str] = Field(default=None, max_length=1024, description="URL to AI background removed/enhanced image")

class ProductImageCreate(ProductImageBase):
    product_id: int = Field(..., description="Foreign key referencing products.id")

class ProductImageRead(ProductImageBase):
    id: int
    product_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ImageEnhancePreviewResponse(BaseModel):
    original_url: str = Field(..., description="URL to raw preview upload")
    processed_url: str = Field(..., description="URL to enhanced studio processed preview")
    width: int = Field(1024, description="Width in pixels")
    height: int = Field(1024, description="Height in pixels")
    background_mode: str = Field("white", description="Studio background theme used")
    pipeline_stages: list[str] = Field(default_factory=list, description="List of enhancement pipeline stages applied")

