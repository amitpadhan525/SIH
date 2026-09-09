import pytest
from decimal import Decimal
from fastapi.testclient import TestClient
from backend.app.models import User, Artisan, Product, Inquiry


def test_sync_batch_create_and_idempotency(client: TestClient, db_session):
    # Ensure artisan exists
    artisan = db_session.get(Artisan, 1)
    if not artisan:
        user = User(id=1, name="Sunita Devi", phone="+919876543210", role="artisan")
        artisan = Artisan(id=1, user_id=1, craft_type="Madhubani Painting")
        db_session.add(user)
        db_session.add(artisan)
        db_session.commit()

    action_id_1 = "offline-uuid-test-001"
    payload = {
        "artisan_id": 1,
        "actions": [
            {
                "client_action_id": action_id_1,
                "action_type": "create_product",
                "payload": {
                    "name": "Terracotta Diya Set",
                    "category": "Pottery",
                    "price": "450.00",
                    "stock_quantity": 10,
                    "unit": "set",
                    "status": "draft",
                    "story": "Hand-molded traditional clay oil lamps",
                },
            }
        ],
    }

    # 1. First sync submission
    res = client.post("/sync/batch", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert data["applied_count"] == 1
    assert data["already_processed_count"] == 0
    server_prod_id = data["results"][0]["server_id"]
    assert server_prod_id is not None
    assert data["results"][0]["status"] == "applied"

    # Verify DB record
    created_product = db_session.get(Product, server_prod_id)
    assert created_product is not None
    assert created_product.name == "Terracotta Diya Set"
    assert created_product.price == Decimal("450.00")

    # 2. Resend same payload with identical client_action_id (idempotency check)
    res_retry = client.post("/sync/batch", json=payload)
    assert res_retry.status_code == 200
    data_retry = res_retry.json()
    assert data_retry["applied_count"] == 0
    assert data_retry["already_processed_count"] == 1
    assert data_retry["results"][0]["status"] == "already_processed"
    assert data_retry["results"][0]["server_id"] == server_prod_id


def test_sync_batch_update_product_and_inquiry(client: TestClient, db_session):
    artisan = db_session.get(Artisan, 1)
    if not artisan:
        user = User(id=1, name="Sunita Devi", phone="+919876543210", role="artisan")
        artisan = Artisan(id=1, user_id=1, craft_type="Madhubani Painting")
        db_session.add(user)
        db_session.add(artisan)
        db_session.commit()

    # Create existing product and inquiry
    product = Product(
        artisan_id=1,
        name="Dhokra Horse",
        category="Metal Craft",
        price=Decimal("1200.00"),
        status="draft",
    )
    db_session.add(product)
    db_session.commit()
    db_session.refresh(product)

    inquiry = Inquiry(
        product_id=product.id,
        buyer_name="Ananya Sharma",
        buyer_email="ananya@buyer.com",
        buyer_phone="+919123456780",
        buyer_type="b2b_wholesale",
        quantity=50,
        status="pending",
    )
    db_session.add(inquiry)
    db_session.commit()
    db_session.refresh(inquiry)

    payload = {
        "artisan_id": 1,
        "actions": [
            {
                "client_action_id": "offline-uuid-test-002",
                "action_type": "update_product",
                "payload": {
                    "id": product.id,
                    "price": "1450.00",
                    "status": "published",
                },
            },
            {
                "client_action_id": "offline-uuid-test-003",
                "action_type": "update_inquiry_status",
                "payload": {
                    "inquiry_id": inquiry.id,
                    "status": "contacted",
                },
            },
        ],
    }

    res = client.post("/sync/batch", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["applied_count"] == 2
    assert data["failed_count"] == 0

    db_session.refresh(product)
    db_session.refresh(inquiry)
    assert product.price == Decimal("1450.00")
    assert product.status == "published"
    assert inquiry.status == "contacted"


def test_sync_delta_endpoint(client: TestClient, db_session):
    res = client.get("/sync/delta?artisan_id=1")
    assert res.status_code == 200
    data = res.json()
    assert "server_time" in data
    assert "products" in data
    assert "inquiries" in data
    assert isinstance(data["products"], list)
