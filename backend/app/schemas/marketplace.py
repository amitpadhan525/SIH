from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class PublicMarketplaceProduct(BaseModel):
    id: int
    artisan_id: int
    artisan_name: str
    artisan_location: Optional[str] = None
    craft_type: Optional[str] = None
    name: str
    category: str
    description: Optional[str] = None
    material: Optional[str] = None
    price: Optional[Decimal] = None
    image_urls: List[str] = Field(default_factory=list)
    created_at: datetime


class ONDCExportItem(BaseModel):
    id: str
    descriptor: Dict[str, Any]
    price: Dict[str, Any]
    category_id: str
    fulfillment_id: str
    tags: List[Dict[str, Any]]


class ONDCCatalogExport(BaseModel):
    bpp_id: str
    bpp_descriptor: Dict[str, Any]
    items: List[ONDCExportItem]
    generated_at: datetime


class GeMExportCatalog(BaseModel):
    product_code: str
    title: str
    category: str
    artisan_origin: str
    material: Optional[str]
    unit_price_inr: Optional[Decimal]
    hsn_code: str
    gst_rate_percent: float
    bulk_minimum_order_qty: int
