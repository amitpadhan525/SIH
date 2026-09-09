import os
from decimal import Decimal
from typing import Dict, Any
from fastapi import APIRouter, Depends, status
from fastapi.responses import HTMLResponse, FileResponse
from sqlalchemy.orm import Session
from sqlalchemy import select, func

from backend.app.db.session import get_db
from backend.app.models import User, Artisan, Product, ProductImage, Inquiry

router = APIRouter(prefix="/admin", tags=["Admin Portal"])

STATIC_ADMIN_INDEX = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "static", "admin", "index.html"
)


@router.get("/portal", response_class=FileResponse)
def get_admin_portal_page():
    """
    Renders and serves the interactive Web Admin & Buyer Discovery portal.
    """
    return FileResponse(STATIC_ADMIN_INDEX, media_type="text/html")



@router.get("/stats", status_code=status.HTTP_200_OK)
def get_admin_dashboard_stats(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """
    Returns high-level aggregate metrics for the web dashboard:
    artisan count, product count, total catalog value, inquiries breakdown, and ONDC readiness.
    """
    total_artisans = db.scalar(select(func.count(Artisan.id))) or 0
    total_products = db.scalar(select(func.count(Product.id))) or 0
    published_products = db.scalar(
        select(func.count(Product.id)).where(Product.status == "published")
    ) or 0
    draft_products = db.scalar(
        select(func.count(Product.id)).where(Product.status == "draft")
    ) or 0

    total_images = db.scalar(select(func.count(ProductImage.id))) or 0
    total_inquiries = db.scalar(select(func.count(Inquiry.id))) or 0
    pending_inquiries = db.scalar(
        select(func.count(Inquiry.id)).where(Inquiry.status == "pending")
    ) or 0

    # Calculate total catalog monetary value
    catalog_value = db.scalar(
        select(func.sum(Product.price)).where(Product.price.isnot(None))
    ) or Decimal("0.00")

    # Group products by craft category
    categories_res = db.execute(
        select(Product.category, func.count(Product.id))
        .group_by(Product.category)
    ).all()

    category_distribution = {cat: count for cat, count in categories_res}

    return {
        "success": True,
        "metrics": {
            "total_artisans": total_artisans,
            "total_products": total_products,
            "published_products": published_products,
            "draft_products": draft_products,
            "enhanced_images_count": total_images,
            "total_buyer_inquiries": total_inquiries,
            "pending_inquiries": pending_inquiries,
            "total_catalog_value_inr": float(catalog_value),
            "ondc_ready_count": published_products,
            "gem_eligible_count": published_products,
        },
        "category_distribution": category_distribution,
    }
