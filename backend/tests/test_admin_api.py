from decimal import Decimal
from fastapi.testclient import TestClient
from backend.app.models import User, Artisan, Product, Inquiry


def test_admin_stats_metrics(client: TestClient, db_session):
    # Ensure artisan exists
    artisan = db_session.get(Artisan, 1)
    if not artisan:
        user = User(id=1, name="Sunita Devi", phone="+919876543210", role="artisan")
        artisan = Artisan(id=1, user_id=1, craft_type="Madhubani Painting")
        db_session.add(user)
        db_session.add(artisan)
        db_session.commit()

    # Create a test product
    product = Product(
        artisan_id=1,
        name="Handcrafted Silk Scarf",
        category="Textiles",
        price=Decimal("1500.00"),
        status="published",
    )
    db_session.add(product)
    db_session.commit()

    res = client.get("/admin/stats")
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert "metrics" in data
    metrics = data["metrics"]
    assert metrics["total_artisans"] >= 1
    assert metrics["total_products"] >= 1
    assert metrics["published_products"] >= 1
    assert metrics["total_catalog_value_inr"] >= 1500.0
    assert "category_distribution" in data
    assert "Textiles" in data["category_distribution"]


def test_admin_portal_html_delivery(client: TestClient):
    res = client.get("/admin/portal")
    assert res.status_code == 200
    assert "text/html" in res.headers["content-type"]
    assert "Artisan Studio AI" in res.text
    assert "SIH 2026" in res.text
