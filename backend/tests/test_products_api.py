import pytest
from decimal import Decimal
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from backend.app.models.user import User
from backend.app.models.artisan import Artisan
from backend.app.models.product import Product
from backend.app.models.product_image import ProductImage


def test_create_product_success(client: TestClient, sample_artisan: Artisan, auth_headers: dict):
    payload = {
        "name": "Handmade Cotton Bag",
        "category": "Handicraft",
        "description": "Traditional handmade cotton bag",
        "material": "Cotton",
        "price": "650.50",
    }
    response = client.post("/products", json=payload, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()

    assert data["id"] is not None
    assert data["artisan_id"] == sample_artisan.id
    assert data["name"] == "Handmade Cotton Bag"
    assert data["category"] == "Handicraft"
    assert data["description"] == "Traditional handmade cotton bag"
    assert data["material"] == "Cotton"
    assert data["price"] == "650.50"
    assert data["status"] == "draft"  # Default status
    assert "created_at" in data
    assert "updated_at" in data


def test_create_product_with_explicit_status(client: TestClient, sample_artisan: Artisan, auth_headers: dict):
    payload = {
        "name": "Madhubani Wall Frame",
        "category": "Paintings",
        "price": "1200.00",
        "status": "published",
    }
    response = client.post("/products", json=payload, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "published"


def test_create_product_unauthenticated(client: TestClient):
    payload = {
        "name": "Anonymous Product",
        "category": "Handicraft",
        "price": "500.00",
    }
    response = client.post("/products", json=payload)
    assert response.status_code == 401


def test_create_product_invalid_price_negative(client: TestClient, sample_artisan: Artisan, auth_headers: dict):
    payload = {
        "name": "Negative Price Product",
        "category": "Handicraft",
        "price": "-100.00",
    }
    response = client.post("/products", json=payload, headers=auth_headers)
    assert response.status_code == 422


def test_create_product_invalid_name_empty(client: TestClient, sample_artisan: Artisan, auth_headers: dict):
    payload = {
        "name": "   ",
        "category": "Handicraft",
        "price": "100.00",
    }
    response = client.post("/products", json=payload, headers=auth_headers)
    assert response.status_code == 422


def test_create_product_invalid_status(client: TestClient, sample_artisan: Artisan, auth_headers: dict):
    payload = {
        "name": "Invalid Status Product",
        "category": "Handicraft",
        "status": "invalid_status",
    }
    response = client.post("/products", json=payload, headers=auth_headers)
    assert response.status_code == 422


def test_get_all_products_empty(client: TestClient):
    response = client.get("/products")
    assert response.status_code == 200
    assert response.json() == []


def test_get_products_pagination_and_ordering(client: TestClient, sample_artisan: Artisan, db_session: Session):
    for i in range(1, 6):
        product = Product(
            artisan_id=sample_artisan.id,
            name=f"Product {i}",
            category="Craft",
            price=Decimal(f"{i * 100}.00"),
            status="draft",
        )
        db_session.add(product)
    db_session.commit()

    # Page 1, page_size 2
    r1 = client.get("/products?page=1&page_size=2")
    assert r1.status_code == 200
    d1 = r1.json()
    assert len(d1) == 2
    assert d1[0]["name"] == "Product 1"
    assert d1[1]["name"] == "Product 2"

    # Page 2, page_size 2
    r2 = client.get("/products?page=2&page_size=2")
    assert r2.status_code == 200
    d2 = r2.json()
    assert len(d2) == 2
    assert d2[0]["name"] == "Product 3"
    assert d2[1]["name"] == "Product 4"

    # Page 3, page_size 2
    r3 = client.get("/products?page=3&page_size=2")
    assert r3.status_code == 200
    d3 = r3.json()
    assert len(d3) == 1
    assert d3[0]["name"] == "Product 5"


def test_get_products_filtering_category(client: TestClient, sample_artisan: Artisan, db_session: Session):
    p1 = Product(artisan_id=sample_artisan.id, name="Pottery Vase", category="Pottery", price=Decimal("300.00"))
    p2 = Product(artisan_id=sample_artisan.id, name="Silk Scarf", category="Textiles", price=Decimal("800.00"))
    db_session.add_all([p1, p2])
    db_session.commit()

    res = client.get("/products?category=Pottery")
    assert res.status_code == 200
    data = res.json()
    assert len(data) == 1
    assert data[0]["name"] == "Pottery Vase"


def test_get_products_filtering_status(client: TestClient, sample_artisan: Artisan, db_session: Session):
    p1 = Product(artisan_id=sample_artisan.id, name="Draft Item", category="Art", status="draft")
    p2 = Product(artisan_id=sample_artisan.id, name="Live Item", category="Art", status="published")
    db_session.add_all([p1, p2])
    db_session.commit()

    res = client.get("/products?status=published")
    assert res.status_code == 200
    data = res.json()
    assert len(data) == 1
    assert data[0]["name"] == "Live Item"


def test_get_products_filtering_artisan_id(
    client: TestClient, sample_artisan: Artisan, second_artisan: Artisan, db_session: Session
):
    p1 = Product(artisan_id=sample_artisan.id, name="Sunita Item", category="Art")
    p2 = Product(artisan_id=second_artisan.id, name="Gopal Item", category="Art")
    db_session.add_all([p1, p2])
    db_session.commit()

    res = client.get(f"/products?artisan_id={second_artisan.id}")
    assert res.status_code == 200
    data = res.json()
    assert len(data) == 1
    assert data[0]["name"] == "Gopal Item"
    assert data[0]["artisan_id"] == second_artisan.id


def test_get_single_product_success(client: TestClient, sample_artisan: Artisan, db_session: Session):
    product = Product(
        artisan_id=sample_artisan.id,
        name="Handmade Clay Mug",
        category="Pottery",
        description="Terracotta coffee mug",
        material="Clay",
        price=Decimal("250.00"),
        status="published",
    )
    db_session.add(product)
    db_session.commit()
    db_session.refresh(product)

    res = client.get(f"/products/{product.id}")
    assert res.status_code == 200
    data = res.json()
    assert data["id"] == product.id
    assert data["name"] == "Handmade Clay Mug"
    assert data["price"] == "250.00"


def test_get_single_product_not_found(client: TestClient):
    res = client.get("/products/999999")
    assert res.status_code == 404
    assert res.json()["detail"] == "Product not found"


def test_update_product_success(client: TestClient, sample_artisan: Artisan, auth_headers: dict, db_session: Session):
    product = Product(
        artisan_id=sample_artisan.id,
        name="Original Title",
        category="Craft",
        price=Decimal("100.00"),
        status="draft",
    )
    db_session.add(product)
    db_session.commit()
    db_session.refresh(product)

    update_payload = {
        "name": "Updated Title",
        "price": "175.50",
        "status": "published",
        "description": "Updated new description",
    }
    res = client.put(f"/products/{product.id}", json=update_payload, headers=auth_headers)
    assert res.status_code == 200
    data = res.json()
    assert data["name"] == "Updated Title"
    assert data["price"] == "175.50"
    assert data["status"] == "published"
    assert data["description"] == "Updated new description"
    assert data["category"] == "Craft"  # Unchanged


def test_update_product_not_found(client: TestClient, auth_headers: dict):
    res = client.put("/products/999999", json={"name": "New Name"}, headers=auth_headers)
    assert res.status_code == 404
    assert res.json()["detail"] == "Product not found"


def test_update_product_disallows_ownership_change(
    client: TestClient, sample_artisan: Artisan, second_artisan: Artisan, auth_headers: dict, db_session: Session
):
    product = Product(
        artisan_id=sample_artisan.id,
        name="Original Item",
        category="Craft",
        price=Decimal("100.00"),
    )
    db_session.add(product)
    db_session.commit()
    db_session.refresh(product)

    # Attempt to change artisan_id ownership
    payload = {
        "artisan_id": second_artisan.id,
        "name": "Hijacked Item Name",
    }
    res = client.put(f"/products/{product.id}", json=payload, headers=auth_headers)
    assert res.status_code == 200
    data = res.json()
    assert data["artisan_id"] == sample_artisan.id  # Unaltered!
    assert data["name"] == "Hijacked Item Name"


def test_delete_product_success_and_cascade_images(
    client: TestClient, sample_artisan: Artisan, auth_headers: dict, db_session: Session
):
    product = Product(
        artisan_id=sample_artisan.id,
        name="Item To Delete",
        category="Craft",
        price=Decimal("200.00"),
    )
    db_session.add(product)
    db_session.commit()
    db_session.refresh(product)

    image = ProductImage(
        product_id=product.id,
        original_url="https://example.com/img1.jpg",
    )
    db_session.add(image)
    db_session.commit()
    db_session.refresh(image)

    product_id = product.id
    image_id = image.id

    # Delete product
    res = client.delete(f"/products/{product_id}", headers=auth_headers)
    assert res.status_code == 204

    # Verify 404 upon GET
    get_res = client.get(f"/products/{product_id}")
    assert get_res.status_code == 404

    # Verify image was deleted from DB via cascade
    assert db_session.get(Product, product_id) is None
    assert db_session.get(ProductImage, image_id) is None


def test_delete_product_not_found(client: TestClient, auth_headers: dict):
    res = client.delete("/products/999999", headers=auth_headers)
    assert res.status_code == 404
    assert res.json()["detail"] == "Product not found"
