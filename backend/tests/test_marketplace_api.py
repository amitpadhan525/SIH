import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from backend.app.main import app
from backend.app.models.artisan import Artisan
from backend.app.models.product import Product
from backend.app.models.user import User

client = TestClient(app)


@pytest.fixture
def test_setup():
    """Seeds a test artisan and products for marketplace tests."""
    from backend.app.db.session import SessionLocal

    with SessionLocal() as db:
        user = db.get(User, 99)
        if not user:
            user = User(
                id=99,
                name="Rameshwar Mahapatra",
                phone="+919123456780",
                role="artisan",
                language="or",
                location="Raghurajpur, Odisha",
            )
            artisan = Artisan(id=99, user_id=99, craft_type="Pattachitra Painting")
            db.add(user)
            db.add(artisan)
            db.commit()

        # Product 1: Published
        p1 = db.get(Product, 1001)
        if not p1:
            p1 = Product(
                id=1001,
                artisan_id=99,
                name="Traditional Palm Leaf Pattachitra Scroll",
                category="Paintings",
                description="Intricate handmade mythological painting on treated palm leaves with natural mineral pigments.",
                material="Palm Leaf & Mineral Colors",
                price=3200.00,
                status="published",
            )
            db.add(p1)

        # Product 2: Draft (should NOT appear in public marketplace)
        p2 = db.get(Product, 1002)
        if not p2:
            p2 = Product(
                id=1002,
                artisan_id=99,
                name="Unfinished Wooden Mask",
                category="Woodwork",
                description="Draft wooden sculpture in progress.",
                material="Teak Wood",
                price=1500.00,
                status="draft",
            )
            db.add(p2)

        db.commit()

    yield 99, 1001, 1002


def test_submit_buyer_inquiry(test_setup):
    """Test public B2B inquiry submission."""
    artisan_id, published_id, _ = test_setup

    payload = {
        "buyer_name": "FabIndia Sourcing Desk",
        "buyer_email": "procurement@fabindia.com",
        "buyer_phone": "+919811223344",
        "buyer_type": "wholesale_b2b",
        "quantity": 25,
        "target_price": 2800.00,
        "message": "We would like to order 25 units for our festive Diwali collection.",
    }

    response = client.post(f"/products/{published_id}/inquiries", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["buyer_name"] == "FabIndia Sourcing Desk"
    assert data["quantity"] == 25
    assert data["status"] == "pending"
    assert data["product_id"] == published_id


def test_submit_inquiry_nonexistent_product():
    """Test inquiry fails for non-existent product."""
    payload = {
        "buyer_name": "Test Buyer",
        "buyer_email": "test@example.com",
        "buyer_phone": "+919876543210",
        "quantity": 1,
    }
    response = client.post("/products/999999/inquiries", json=payload)
    assert response.status_code == 404


def test_get_artisan_inquiries_and_status_update(test_setup):
    """Test artisan views received inquiries and updates lifecycle status."""
    artisan_id, published_id, _ = test_setup

    # 1. Fetch artisan's inquiries
    response = client.get(f"/artisans/{artisan_id}/inquiries")
    assert response.status_code == 200
    inquiries = response.json()
    assert len(inquiries) >= 1

    target_inq = inquiries[0]
    inquiry_id = target_inq["id"]
    assert "Traditional Palm Leaf Pattachitra" in target_inq["product_name"]

    # 2. Update status to 'contacted'
    update_res = client.put(f"/inquiries/{inquiry_id}/status", json={"status": "contacted"})
    assert update_res.status_code == 200
    assert update_res.json()["status"] == "contacted"

    # 3. Invalid status rejected
    invalid_res = client.put(f"/inquiries/{inquiry_id}/status", json={"status": "invalid_status"})
    assert invalid_res.status_code == 400


def test_marketplace_public_feed(test_setup):
    """Test public marketplace feed returns only published products and supports keyword search."""
    artisan_id, published_id, draft_id = test_setup

    response = client.get("/marketplace/products")
    assert response.status_code == 200
    products = response.json()

    # Verify published product is present, draft is omitted
    product_ids = [p["id"] for p in products]
    assert published_id in product_ids
    assert draft_id not in product_ids

    # Search by keyword
    search_res = client.get("/marketplace/products?query=Pattachitra")
    assert search_res.status_code == 200
    search_ids = [p["id"] for p in search_res.json()]
    assert published_id in search_ids

    # Filter by category
    cat_res = client.get("/marketplace/products?category=Paintings")
    assert cat_res.status_code == 200
    assert len(cat_res.json()) >= 1


def test_export_ondc_format(test_setup):
    """Test ONDC protocol standard item catalog generation."""
    _, published_id, _ = test_setup

    response = client.get(f"/marketplace/export/ondc/{published_id}")
    assert response.status_code == 200
    data = response.json()

    assert data["id"] == f"artisan-item-{published_id}"
    assert "Palm Leaf" in data["descriptor"]["name"]
    assert data["price"]["currency"] == "INR"
    assert "tags" in data
    assert len(data["tags"]) >= 2


def test_export_gem_format(test_setup):
    """Test Government e-Marketplace (GeM) standard listing payload."""
    _, published_id, _ = test_setup

    response = client.get(f"/marketplace/export/gem/{published_id}")
    assert response.status_code == 200
    data = response.json()

    assert data["product_code"] == f"GEM-ARTISAN-{published_id:06d}"
    assert data["hsn_code"] == "9701"  # Paintings HSN
    assert data["gst_rate_percent"] == 5.0
    assert data["bulk_minimum_order_qty"] == 10
