from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.core.security import get_current_artisan
from backend.app.db.session import get_db
from backend.app.models.artisan import Artisan
from backend.app.models.product import Product
from backend.app.schemas.product import ProductCreate, ProductUpdate, ProductRead

router = APIRouter()


@router.post(
    "",
    response_model=ProductRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new product",
    description="Creates a product securely linked to the currently authenticated artisan.",
)
def create_product(
    product_in: ProductCreate,
    current_artisan: Artisan = Depends(get_current_artisan),
    db: Session = Depends(get_db),
) -> Product:
    # Derive ownership directly from authenticated artisan JWT session
    product = Product(
        artisan_id=current_artisan.id,
        name=product_in.name,
        category=product_in.category,
        description=product_in.description,
        material=product_in.material,
        price=product_in.price,
        status=product_in.status,
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


@router.get(
    "",
    response_model=List[ProductRead],
    status_code=status.HTTP_200_OK,
    summary="List products with pagination and filters",
    description="Retrieve a paginated list of products with optional filtering by category, status, or artisan_id.",
)
def get_products(
    page: int = Query(default=1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(default=20, ge=1, le=100, description="Items per page (max 100)"),
    category: Optional[str] = Query(default=None, description="Filter by exact category name"),
    status_filter: Optional[str] = Query(default=None, alias="status", description="Filter by status (draft, published, archived)"),
    artisan_id: Optional[int] = Query(default=None, description="Filter by artisan ID"),
    db: Session = Depends(get_db),
) -> List[Product]:
    query = select(Product)

    if category is not None:
        query = query.where(Product.category == category.strip())
    if status_filter is not None:
        query = query.where(Product.status == status_filter.strip().lower())
    if artisan_id is not None:
        query = query.where(Product.artisan_id == artisan_id)

    offset = (page - 1) * page_size
    query = query.order_by(Product.id.asc()).offset(offset).limit(page_size)

    result = db.scalars(query).all()
    return list(result)


@router.get(
    "/{product_id}",
    response_model=ProductRead,
    status_code=status.HTTP_200_OK,
    summary="Get single product by ID",
    description="Retrieve complete details for a specific product by its primary key ID.",
)
def get_product(
    product_id: int,
    db: Session = Depends(get_db),
) -> Product:
    product = db.get(Product, product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found",
        )
    return product


@router.put(
    "/{product_id}",
    response_model=ProductRead,
    status_code=status.HTTP_200_OK,
    summary="Update product details",
    description="Updates existing product fields. Product must belong to the authenticated artisan.",
)
def update_product(
    product_id: int,
    product_in: ProductUpdate,
    current_artisan: Artisan = Depends(get_current_artisan),
    db: Session = Depends(get_db),
) -> Product:
    product = db.get(Product, product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found",
        )

    # IDOR Protection: verify product belongs to the authenticated artisan
    if product.artisan_id != current_artisan.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to modify this product.",
        )

    update_data = product_in.model_dump(exclude_unset=True)

    # Disallow modifying immutable ownership or identifiers
    update_data.pop("id", None)
    update_data.pop("artisan_id", None)

    for field, value in update_data.items():
        setattr(product, field, value)

    db.commit()
    db.refresh(product)
    return product


@router.delete(
    "/{product_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a product",
    description="Deletes a product by ID. Product must belong to the authenticated artisan. Associated product images are automatically cascade-deleted.",
)
def delete_product(
    product_id: int,
    current_artisan: Artisan = Depends(get_current_artisan),
    db: Session = Depends(get_db),
) -> None:
    product = db.get(Product, product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found",
        )

    # IDOR Protection: verify product belongs to the authenticated artisan
    if product.artisan_id != current_artisan.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to delete this product.",
        )

    db.delete(product)
    db.commit()
    return None
