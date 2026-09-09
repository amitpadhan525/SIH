import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from backend.app.main import app
from backend.app.core.security import create_access_token
from backend.app.db.session import SessionLocal
from backend.app.models.user import User
from backend.app.models.artisan import Artisan
from backend.app.models.product import Product
from backend.app.models.inquiry import Inquiry

client = TestClient(app)


@pytest.fixture
def db_session():
    db: Session = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture
def artisan_pair(db_session: Session):
    """Creates two distinct artisans A and B for IDOR ownership validation."""
    # Artisan A
    user_a = db_session.query(User).filter(User.phone == "+919999111111").first()
    if not user_a:
        user_a = User(name="Artisan Alice", phone="+919999111111", role="artisan", language="en")
        db_session.add(user_a)
        db_session.commit()
        db_session.refresh(user_a)

    artisan_a = db_session.query(Artisan).filter(Artisan.user_id == user_a.id).first()
    if not artisan_a:
        artisan_a = Artisan(user_id=user_a.id, craft_type="Ikat Weaving", is_profile_complete=True)
        db_session.add(artisan_a)
        db_session.commit()
        db_session.refresh(artisan_a)

    # Artisan B
    user_b = db_session.query(User).filter(User.phone == "+919999222222").first()
    if not user_b:
        user_b = User(name="Artisan Bob", phone="+919999222222", role="artisan", language="en")
        db_session.add(user_b)
        db_session.commit()
        db_session.refresh(user_b)

    artisan_b = db_session.query(Artisan).filter(Artisan.user_id == user_b.id).first()
    if not artisan_b:
        artisan_b = Artisan(user_id=user_b.id, craft_type="Dokra Casting", is_profile_complete=True)
        db_session.add(artisan_b)
        db_session.commit()
        db_session.refresh(artisan_b)

    token_a = create_access_token({"sub": str(user_a.id), "role": "artisan", "name": user_a.name, "phone": user_a.phone})
    token_b = create_access_token({"sub": str(user_b.id), "role": "artisan", "name": user_b.name, "phone": user_b.phone})

    # Product owned by Artisan B
    product_b = db_session.query(Product).filter(Product.artisan_id == artisan_b.id, Product.name == "Bob Dokra Bell").first()
    if not product_b:
        product_b = Product(
            artisan_id=artisan_b.id,
            name="Bob Dokra Bell",
            category="Metalwork",
            price=2500.0,
            status="published",
        )
        db_session.add(product_b)
        db_session.commit()
        db_session.refresh(product_b)

    return {
        "artisan_a": artisan_a,
        "token_a": token_a,
        "artisan_b": artisan_b,
        "token_b": token_b,
        "product_b": product_b,
    }


def test_artisan_cannot_modify_other_artisan_product(artisan_pair: dict):
    """Verify Artisan A cannot update Artisan B's product (403 Forbidden)."""
    headers = {"Authorization": f"Bearer {artisan_pair['token_a']}"}
    product_b_id = artisan_pair["product_b"].id

    payload = {"name": "Hacked Product Name"}
    response = client.put(f"/products/{product_b_id}", json=payload, headers=headers)
    assert response.status_code == 403
    assert "permission" in response.json()["detail"].lower()


def test_artisan_cannot_delete_other_artisan_product(artisan_pair: dict):
    """Verify Artisan A cannot delete Artisan B's product (403 Forbidden)."""
    headers = {"Authorization": f"Bearer {artisan_pair['token_a']}"}
    product_b_id = artisan_pair["product_b"].id

    response = client.delete(f"/products/{product_b_id}", headers=headers)
    assert response.status_code == 403


def test_artisan_cannot_view_other_artisan_inquiries(artisan_pair: dict):
    """Verify Artisan A cannot access /artisans/{artisan_b_id}/inquiries (403 Forbidden)."""
    headers = {"Authorization": f"Bearer {artisan_pair['token_a']}"}
    artisan_b_id = artisan_pair["artisan_b"].id

    response = client.get(f"/artisans/{artisan_b_id}/inquiries", headers=headers)
    assert response.status_code == 403
