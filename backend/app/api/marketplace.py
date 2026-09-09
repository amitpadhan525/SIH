from datetime import datetime, timezone
from decimal import Decimal
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session, joinedload

from backend.app.db.session import get_db
from backend.app.models.artisan import Artisan
from backend.app.models.product import Product
from backend.app.schemas.marketplace import (
    GeMExportCatalog,
    ONDCExportItem,
    PublicMarketplaceProduct,
)

router = APIRouter(prefix="/marketplace", tags=["Marketplace Discovery & Exports"])


@router.get(
    "/products",
    response_model=List[PublicMarketplaceProduct],
    status_code=status.HTTP_200_OK,
    summary="Public marketplace feed with search and filtering",
)
def get_marketplace_products(
    query: Optional[str] = Query(None, description="Search keyword in product name, material, or description"),
    category: Optional[str] = Query(None, description="Filter by craft category"),
    min_price: Optional[Decimal] = Query(None, ge=0),
    max_price: Optional[Decimal] = Query(None, ge=0),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """
    Public catalog discovery endpoint for buyers. Only displays 'published' artisan products.
    """
    stmt = (
        select(Product)
        .options(joinedload(Product.artisan).joinedload(Artisan.user), joinedload(Product.images))
        .where(Product.status == "published")
    )

    if category:
        stmt = stmt.where(Product.category.ilike(f"%{category}%"))

    if min_price is not None:
        stmt = stmt.where(Product.price >= min_price)

    if max_price is not None:
        stmt = stmt.where(Product.price <= max_price)

    if query:
        search_filter = or_(
            Product.name.ilike(f"%{query}%"),
            Product.material.ilike(f"%{query}%"),
            Product.description.ilike(f"%{query}%"),
        )
        stmt = stmt.where(search_filter)

    stmt = stmt.order_by(Product.created_at.desc()).offset(offset).limit(limit)
    products = db.execute(stmt).unique().scalars().all()

    feed = []
    for p in products:
        artisan_user = p.artisan.user if p.artisan else None
        artisan_name = artisan_user.name if artisan_user else "Traditional Artisan"
        artisan_loc = artisan_user.location if artisan_user else "India"
        craft = p.artisan.craft_type if p.artisan else p.category
        images = [img.processed_url for img in p.images]

        feed.append(
            PublicMarketplaceProduct(
                id=p.id,
                artisan_id=p.artisan_id,
                artisan_name=artisan_name,
                artisan_location=artisan_loc,
                craft_type=craft,
                name=p.name,
                category=p.category,
                description=p.description,
                material=p.material,
                price=p.price,
                image_urls=images,
                created_at=p.created_at,
            )
        )

    return feed


@router.get(
    "/export/ondc/{product_id}",
    response_model=ONDCExportItem,
    status_code=status.HTTP_200_OK,
    summary="Export product in standard ONDC Retail Catalog Protocol JSON",
)
def export_product_ondc(product_id: int, db: Session = Depends(get_db)):
    """
    Formats the artisan product into standard ONDC (Open Network for Digital Commerce) protocol JSON.
    """
    product = (
        db.execute(
            select(Product)
            .options(joinedload(Product.artisan).joinedload(Artisan.user), joinedload(Product.images))
            .where(Product.id == product_id)
        )
        .unique()
        .scalar_one_or_none()
    )

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with id {product_id} not found",
        )

    artisan_user = product.artisan.user if product.artisan else None
    images = [img.processed_url for img in product.images]
    price_val = str(product.price or Decimal("0.00"))

    return ONDCExportItem(
        id=f"artisan-item-{product.id}",
        descriptor={
            "name": product.name,
            "code": f"ART-{product.category[:3].upper()}-{product.id}",
            "symbol": images[0] if images else "",
            "short_desc": product.description[:120] if product.description else product.name,
            "long_desc": product.description or product.name,
            "images": images,
        },
        price={
            "currency": "INR",
            "value": price_val,
            "maximum_value": price_val,
        },
        category_id=f"ONDC:RET12-{product.category.upper()}",
        fulfillment_id="F1",
        tags=[
            {"code": "origin", "list": [{"code": "country", "value": "IND"}, {"code": "state", "value": artisan_user.location if artisan_user else "India"}]},
            {"code": "attribute", "list": [{"code": "material", "value": product.material or "Handcrafted"}, {"code": "handmade", "value": "true"}]},
            {"code": "artisan", "list": [{"code": "artisan_name", "value": artisan_user.name if artisan_user else "Rural Artisan"}]},
        ],
    )


@router.get(
    "/export/gem/{product_id}",
    response_model=GeMExportCatalog,
    status_code=status.HTTP_200_OK,
    summary="Export product for Government e-Marketplace (GeM) listing",
)
def export_product_gem(product_id: int, db: Session = Depends(get_db)):
    """
    Generates standard Government e-Marketplace (GeM) bulk procurement schema.
    """
    product = (
        db.execute(
            select(Product)
            .options(joinedload(Product.artisan).joinedload(Artisan.user))
            .where(Product.id == product_id)
        )
        .unique()
        .scalar_one_or_none()
    )

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with id {product_id} not found",
        )

    artisan_user = product.artisan.user if product.artisan else None

    # HSN Code Mapping
    hsn_mapping = {
        "textiles": "5208",
        "handloom": "5208",
        "pottery": "6912",
        "terracotta": "6912",
        "metalwork": "7419",
        "dokra": "7419",
        "paintings": "9701",
        "woodwork": "4420",
    }

    cat_lower = product.category.lower()
    matched_hsn = "9999"
    for k, hsn in hsn_mapping.items():
        if k in cat_lower:
            matched_hsn = hsn
            break

    return GeMExportCatalog(
        product_code=f"GEM-ARTISAN-{product.id:06d}",
        title=product.name,
        category=f"Handicrafts & Handlooms - {product.category}",
        artisan_origin=artisan_user.location if artisan_user else "India",
        material=product.material or "Natural Traditional Material",
        unit_price_inr=product.price,
        hsn_code=matched_hsn,
        gst_rate_percent=5.0,  # Concessional 5% GST for registered Indian artisan goods
        bulk_minimum_order_qty=10,
    )
