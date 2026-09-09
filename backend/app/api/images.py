from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from backend.app.db.session import get_db
from backend.app.models.product import Product
from backend.app.models.product_image import ProductImage
from backend.app.schemas.product_image import ProductImageRead, ImageEnhancePreviewResponse
from backend.app.services.storage_service import storage_service, StorageSecurityError
from backend.app.ai.image_processor import image_processor

router = APIRouter()


@router.post(
    "/products/{product_id}/images",
    response_model=ProductImageRead,
    status_code=status.HTTP_201_CREATED,
    summary="Upload and enhance product photograph",
    tags=["Product Images"]
)
async def upload_product_image(
    product_id: int,
    file: UploadFile = File(..., description="Product photograph (JPEG, PNG, or WEBP, max 10MB)"),
    background_mode: str = Query(
        "white",
        description="Studio background mode",
        enum=["white", "grey", "warm", "transparent"]
    ),
    db: Session = Depends(get_db),
) -> ProductImageRead:
    """
    Securely uploads a product photo, processes it through the AI Image Studio pipeline
    (contrast enhancement, background isolation/simplification, 1024x1024 square formatting),
    stores both original and studio versions, and links the image to the product.
    """
    # 1. Verify product exists
    product = db.get(Product, product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with id {product_id} not found."
        )

    # 2. Read and validate raw upload bytes
    try:
        file_bytes = await file.read()
        decoded_image, detected_format = storage_service.validate_image_bytes(file_bytes)
    except StorageSecurityError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc)
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unable to process uploaded image: {exc}"
        )

    # 3. Store raw original image safely
    try:
        orig_rel_url, _ = storage_service.save_original_image(file_bytes, detected_format)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to store original image asset: {exc}"
        )

    # 4. Process image through AI Studio Pipeline
    try:
        processed_image, _ = image_processor.process(
            image=decoded_image,
            background_mode=background_mode
        )
        proc_format = "PNG" if background_mode == "transparent" else "JPEG"
        proc_rel_url, _ = storage_service.save_processed_image(
            image=processed_image,
            format_name=proc_format,
            is_preview=False
        )
    except Exception as exc:
        # Clean up original file if processing failed
        storage_service.delete_file_by_url(orig_rel_url)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Image enhancement pipeline failed: {exc}"
        )

    # 5. Persist ProductImage record in database
    product_image = ProductImage(
        product_id=product_id,
        original_url=orig_rel_url,
        processed_url=proc_rel_url
    )
    db.add(product_image)
    db.commit()
    db.refresh(product_image)

    return ProductImageRead.model_validate(product_image)


@router.get(
    "/products/{product_id}/images",
    response_model=List[ProductImageRead],
    status_code=status.HTTP_200_OK,
    summary="List all images for a product",
    tags=["Product Images"]
)
def list_product_images(
    product_id: int,
    db: Session = Depends(get_db),
) -> List[ProductImageRead]:
    """
    Returns all uploaded and processed studio images associated with a specific product.
    """
    product = db.get(Product, product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with id {product_id} not found."
        )

    images = db.scalars(
        select(ProductImage)
        .where(ProductImage.product_id == product_id)
        .order_by(ProductImage.id.asc())
    ).all()

    return [ProductImageRead.model_validate(img) for img in images]


@router.delete(
    "/products/{product_id}/images/{image_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a product image",
    tags=["Product Images"]
)
def delete_product_image(
    product_id: int,
    image_id: int,
    db: Session = Depends(get_db),
) -> None:
    """
    Deletes a product image record from the database and permanently removes
    the original and processed image assets from storage.
    """
    product = db.get(Product, product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with id {product_id} not found."
        )

    image = db.scalars(
        select(ProductImage)
        .where(ProductImage.id == image_id, ProductImage.product_id == product_id)
    ).first()

    if not image:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Image with id {image_id} not found for product {product_id}."
        )

    # Clean up physical files safely
    storage_service.delete_file_by_url(image.original_url)
    if image.processed_url:
        storage_service.delete_file_by_url(image.processed_url)

    # Delete database record
    db.delete(image)
    db.commit()
    return None


@router.post(
    "/ai/images/enhance",
    response_model=ImageEnhancePreviewResponse,
    status_code=status.HTTP_200_OK,
    summary="Standalone AI studio image enhancement preview",
    tags=["AI Studio"]
)
async def enhance_image_preview(
    file: UploadFile = File(..., description="Product photograph to enhance (max 10MB)"),
    background_mode: str = Query(
        "white",
        description="Studio background theme",
        enum=["white", "grey", "warm", "transparent"]
    ),
) -> ImageEnhancePreviewResponse:
    """
    Accepts a photograph and returns instant before/after preview assets without
    attaching them to a database product record. Ideal for live artisan photo preview.
    """
    try:
        file_bytes = await file.read()
        decoded_image, detected_format = storage_service.validate_image_bytes(file_bytes)
    except StorageSecurityError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc)
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unable to process image: {exc}"
        )

    # Store temporary preview original
    orig_url, _ = storage_service.save_processed_image(
        image=decoded_image,
        format_name=detected_format if detected_format in ("JPEG", "PNG") else "JPEG",
        is_preview=True
    )

    # Process and store preview output
    processed_image, meta = image_processor.process(
        image=decoded_image,
        background_mode=background_mode
    )
    proc_format = "PNG" if background_mode == "transparent" else "JPEG"
    proc_url, _ = storage_service.save_processed_image(
        image=processed_image,
        format_name=proc_format,
        is_preview=True
    )

    return ImageEnhancePreviewResponse(
        original_url=orig_url,
        processed_url=proc_url,
        width=meta["width"],
        height=meta["height"],
        background_mode=meta["background_mode"],
        pipeline_stages=meta["pipeline_stages"]
    )
