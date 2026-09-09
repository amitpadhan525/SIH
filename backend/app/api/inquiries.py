from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.db.session import get_db
from backend.app.models.artisan import Artisan
from backend.app.models.inquiry import Inquiry
from backend.app.models.product import Product
from backend.app.schemas.inquiry import (
    ArtisanInquiryRead,
    InquiryCreate,
    InquiryRead,
    InquiryStatusUpdate,
)

router = APIRouter(tags=["Marketplace Inquiries & B2B"])


@router.post(
    "/products/{product_id}/inquiries",
    response_model=InquiryRead,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a buyer inquiry for a product",
)
def create_product_inquiry(
    product_id: int,
    inquiry_in: InquiryCreate,
    db: Session = Depends(get_db),
):
    """
    Public endpoint for retail and B2B buyers to express purchase/bulk interest.
    """
    product = db.get(Product, product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with id {product_id} not found",
        )

    inquiry = Inquiry(
        product_id=product_id,
        buyer_name=inquiry_in.buyer_name,
        buyer_email=inquiry_in.buyer_email,
        buyer_phone=inquiry_in.buyer_phone,
        buyer_type=inquiry_in.buyer_type,
        quantity=inquiry_in.quantity,
        target_price=inquiry_in.target_price,
        message=inquiry_in.message,
        status="pending",
    )

    db.add(inquiry)
    db.commit()
    db.refresh(inquiry)
    return inquiry


@router.get(
    "/artisans/{artisan_id}/inquiries",
    response_model=List[ArtisanInquiryRead],
    status_code=status.HTTP_200_OK,
    summary="List all buyer inquiries received by an artisan",
)
def get_artisan_inquiries(
    artisan_id: int,
    status_filter: str = None,
    db: Session = Depends(get_db),
):
    """
    Returns inquiries for all products owned by the given artisan.
    """
    artisan = db.get(Artisan, artisan_id)
    if not artisan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Artisan with id {artisan_id} not found",
        )

    stmt = (
        select(Inquiry, Product)
        .join(Product, Inquiry.product_id == Product.id)
        .where(Product.artisan_id == artisan_id)
        .order_by(Inquiry.created_at.desc())
    )

    if status_filter:
        stmt = stmt.where(Inquiry.status == status_filter)

    results = db.execute(stmt).all()
    inquiries_list = []

    for inq, prod in results:
        img_url = prod.images[0].processed_url if prod.images else None
        inquiries_list.append(
            ArtisanInquiryRead(
                id=inq.id,
                product_id=inq.product_id,
                buyer_name=inq.buyer_name,
                buyer_email=inq.buyer_email,
                buyer_phone=inq.buyer_phone,
                buyer_type=inq.buyer_type,
                quantity=inq.quantity,
                target_price=inq.target_price,
                message=inq.message,
                status=inq.status,
                created_at=inq.created_at,
                updated_at=inq.updated_at,
                product_name=prod.name,
                product_price=prod.price,
                product_image_url=img_url,
            )
        )

    return inquiries_list


@router.put(
    "/inquiries/{inquiry_id}/status",
    response_model=InquiryRead,
    status_code=status.HTTP_200_OK,
    summary="Update inquiry lifecycle status",
)
def update_inquiry_status(
    inquiry_id: int,
    status_in: InquiryStatusUpdate,
    db: Session = Depends(get_db),
):
    """
    Allows the artisan to mark inquiries as contacted, accepted, or declined.
    """
    valid_statuses = {"pending", "contacted", "accepted", "declined"}
    if status_in.status not in valid_statuses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid status '{status_in.status}'. Allowed: {sorted(list(valid_statuses))}",
        )

    inquiry = db.get(Inquiry, inquiry_id)
    if not inquiry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Inquiry with id {inquiry_id} not found",
        )

    inquiry.status = status_in.status
    db.commit()
    db.refresh(inquiry)
    return inquiry
