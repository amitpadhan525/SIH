import os
from decimal import Decimal
from typing import Dict, Any, Optional
from fastapi import APIRouter, Depends, status
from fastapi.responses import HTMLResponse, FileResponse
from sqlalchemy.orm import Session
from sqlalchemy import select, func

from backend.app.core.security import get_current_admin
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


@router.get("/inquiries", status_code=status.HTTP_200_OK)
def get_admin_inquiries(
    status_filter: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    """
    Returns all buyer wholesale inquiries across all artisans.
    Strictly protected: Requires authenticated admin JWT session (role == 'admin').
    """
    stmt = select(Inquiry).order_by(Inquiry.created_at.desc())
    if status_filter:
        stmt = stmt.where(Inquiry.status == status_filter)

    inquiries = db.scalars(stmt.offset(offset).limit(limit)).all()
    total_count = db.scalar(
        select(func.count(Inquiry.id)).where(Inquiry.status == status_filter if status_filter else True)
    ) or 0

    items = []
    for inq in inquiries:
        product = inq.product
        artisan = product.artisan if product else None
        artisan_user = artisan.user if artisan else None

        items.append({
            "id": inq.id,
            "product_id": inq.product_id,
            "product_name": product.name if product else None,
            "product_category": product.category if product else None,
            "artisan_id": artisan.id if artisan else None,
            "artisan_name": artisan.artisan_name or (artisan_user.name if artisan_user else None),
            "buyer_name": inq.buyer_name,
            "buyer_email": inq.buyer_email,
            "buyer_phone": inq.buyer_phone,
            "buyer_type": inq.buyer_type,
            "quantity": inq.quantity,
            "target_price": float(inq.target_price) if inq.target_price is not None else None,
            "message": inq.message,
            "status": inq.status,
            "created_at": inq.created_at.isoformat() if inq.created_at else None,
            "updated_at": inq.updated_at.isoformat() if inq.updated_at else None,
        })

    return {
        "success": True,
        "total": total_count,
        "limit": limit,
        "offset": offset,
        "inquiries": items,
    }

