import logging
from datetime import datetime, timezone
from decimal import Decimal
from typing import Dict, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import select, and_

from backend.app.db.session import get_db
from backend.app.models import User, Artisan, Product, ProductImage, Inquiry
from backend.app.schemas.sync import (
    SyncBatchRequest,
    SyncBatchResponse,
    SyncActionResponse,
    SyncDeltaResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/sync", tags=["Offline Sync"])

# In-memory registry of processed client UUIDs to ensure idempotency across retries
_PROCESSED_ACTION_IDS: Dict[str, SyncActionResponse] = {}


@router.post("/batch", response_model=SyncBatchResponse, status_code=status.HTTP_200_OK)
def sync_batch(
    payload: SyncBatchRequest,
    db: Session = Depends(get_db),
):
    """
    Processes a batch of offline actions performed by an artisan (e.g. creating/updating products,
    updating inquiry leads while offline).
    Guarantees strict idempotency via client_action_id.
    """
    artisan = db.scalar(select(Artisan).where(Artisan.id == payload.artisan_id))
    if not artisan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Artisan with ID {payload.artisan_id} does not exist.",
        )

    results = []
    applied_count = 0
    already_processed_count = 0
    failed_count = 0

    for action in payload.actions:
        action_id = action.client_action_id

        # 1. Idempotency check: if already processed, return cached response
        if action_id in _PROCESSED_ACTION_IDS:
            prev_result = _PROCESSED_ACTION_IDS[action_id]
            results.append(
                SyncActionResponse(
                    client_action_id=action_id,
                    status="already_processed",
                    server_id=prev_result.server_id,
                    message="Action was previously processed and applied.",
                    data=prev_result.data,
                )
            )
            already_processed_count += 1
            continue

        # 2. Process by action type
        try:
            if action.action_type == "create_product":
                p_data = action.payload
                price_val = Decimal(str(p_data.get("price", "0.00"))) if p_data.get("price") is not None else None
                new_product = Product(
                    artisan_id=payload.artisan_id,
                    name=p_data.get("name", "Offline Draft Product"),
                    description=p_data.get("description"),
                    category=p_data.get("category", "General Handicrafts"),
                    material=p_data.get("material") or p_data.get("materials"),
                    price=price_val,
                    status=p_data.get("status", "draft"),
                )
                db.add(new_product)
                db.flush()

                action_res = SyncActionResponse(
                    client_action_id=action_id,
                    status="applied",
                    server_id=new_product.id,
                    message="Product successfully synced and created from offline queue.",
                    data={"id": new_product.id, "name": new_product.name, "status": new_product.status},
                )
                db.commit()
                _PROCESSED_ACTION_IDS[action_id] = action_res
                results.append(action_res)
                applied_count += 1

            elif action.action_type == "update_product":
                p_data = action.payload
                server_id = p_data.get("id") or p_data.get("server_id")
                if not server_id:
                    raise ValueError("Product update requires 'id' or 'server_id'")

                product = db.scalar(
                    select(Product).where(
                        and_(Product.id == server_id, Product.artisan_id == payload.artisan_id)
                    )
                )
                if not product:
                    action_res = SyncActionResponse(
                        client_action_id=action_id,
                        status="failed",
                        server_id=server_id,
                        message=f"Product {server_id} not found or does not belong to artisan {payload.artisan_id}",
                    )
                    results.append(action_res)
                    failed_count += 1
                    continue

                for field, val in p_data.items():
                    if field in ("id", "artisan_id", "created_at"):
                        continue
                    if hasattr(product, field):
                        if field == "price" and val is not None:
                            setattr(product, field, Decimal(str(val)))
                        else:
                            setattr(product, field, val)

                db.commit()
                action_res = SyncActionResponse(
                    client_action_id=action_id,
                    status="applied",
                    server_id=product.id,
                    message="Product updated successfully from offline queue.",
                    data={"id": product.id, "name": product.name, "status": product.status},
                )
                _PROCESSED_ACTION_IDS[action_id] = action_res
                results.append(action_res)
                applied_count += 1

            elif action.action_type == "update_inquiry_status":
                i_data = action.payload
                inquiry_id = i_data.get("inquiry_id") or i_data.get("id")
                new_status = i_data.get("status")
                if not inquiry_id or not new_status:
                    raise ValueError("Inquiry update requires 'inquiry_id' and 'status'")

                inquiry = db.scalar(
                    select(Inquiry)
                    .join(Product, Inquiry.product_id == Product.id)
                    .where(and_(Inquiry.id == inquiry_id, Product.artisan_id == payload.artisan_id))
                )
                if not inquiry:
                    action_res = SyncActionResponse(
                        client_action_id=action_id,
                        status="failed",
                        server_id=inquiry_id,
                        message=f"Inquiry {inquiry_id} not found for artisan {payload.artisan_id}",
                    )
                    results.append(action_res)
                    failed_count += 1
                    continue

                inquiry.status = new_status
                db.commit()
                action_res = SyncActionResponse(
                    client_action_id=action_id,
                    status="applied",
                    server_id=inquiry.id,
                    message=f"Inquiry status updated to '{new_status}' successfully.",
                    data={"id": inquiry.id, "status": inquiry.status},
                )
                _PROCESSED_ACTION_IDS[action_id] = action_res
                results.append(action_res)
                applied_count += 1

            else:
                action_res = SyncActionResponse(
                    client_action_id=action_id,
                    status="failed",
                    message=f"Unknown action_type: {action.action_type}",
                )
                results.append(action_res)
                failed_count += 1

        except Exception as e:
            db.rollback()
            logger.exception("Error applying sync action %s", action_id)
            action_res = SyncActionResponse(
                client_action_id=action_id,
                status="failed",
                message=str(e),
            )
            results.append(action_res)
            failed_count += 1

    return SyncBatchResponse(
        success=(failed_count == 0),
        total_actions=len(payload.actions),
        applied_count=applied_count,
        already_processed_count=already_processed_count,
        failed_count=failed_count,
        results=results,
        server_time=datetime.now(timezone.utc),
    )


@router.get("/delta", response_model=SyncDeltaResponse)
def get_sync_delta(
    artisan_id: int = Query(..., description="ID of the artisan"),
    since: Optional[datetime] = Query(None, description="ISO timestamp of last sync"),
    db: Session = Depends(get_db),
):
    """
    Fetches all products and inquiries updated on the server since the specified timestamp.
    Enables low-bandwidth catchup without re-downloading entire catalogs.
    """
    prod_query = select(Product).where(Product.artisan_id == artisan_id)
    if since:
        prod_query = prod_query.where(Product.updated_at >= since)
    products = db.scalars(prod_query).all()

    inq_query = (
        select(Inquiry)
        .join(Product, Inquiry.product_id == Product.id)
        .where(Product.artisan_id == artisan_id)
    )
    if since:
        inq_query = inq_query.where(Inquiry.updated_at >= since)
    inquiries = db.scalars(inq_query).all()

    return SyncDeltaResponse(
        server_time=datetime.now(timezone.utc),
        products=[
            {
                "id": p.id,
                "name": p.name,
                "category": p.category,
                "price": str(p.price) if p.price is not None else None,
                "status": p.status,
                "material": p.material,
                "updated_at": p.updated_at.isoformat() if p.updated_at else None,
            }
            for p in products
        ],
        inquiries=[
            {
                "id": i.id,
                "buyer_name": i.buyer_name,
                "buyer_type": i.buyer_type,
                "status": i.status,
                "quantity": i.quantity,
                "created_at": i.created_at.isoformat() if i.created_at else None,
            }
            for i in inquiries
        ],
    )
