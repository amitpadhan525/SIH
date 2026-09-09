import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from backend.app.main import app
from backend.app.core.security import create_access_token
from backend.app.db.session import SessionLocal
from backend.app.models.user import User
from backend.app.models.artisan import Artisan

client = TestClient(app)


@pytest.fixture
def db_session():
    db: Session = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture
def admin_token(db_session: Session):
    # Ensure admin user exists
    admin_user = db_session.query(User).filter(User.role == "admin").first()
    if not admin_user:
        admin_user = User(
            name="Super Admin",
            phone="+919999900001",
            role="admin",
            language="en",
        )
        db_session.add(admin_user)
        db_session.commit()
        db_session.refresh(admin_user)

    return create_access_token({
        "sub": str(admin_user.id),
        "role": "admin",
        "name": admin_user.name,
        "phone": admin_user.phone,
    })


@pytest.fixture
def artisan_token(db_session: Session):
    artisan_user = db_session.query(User).filter(User.role == "artisan").first()
    if not artisan_user:
        artisan_user = User(
            name="Normal Artisan",
            phone="+919999900002",
            role="artisan",
            language="hi",
        )
        db_session.add(artisan_user)
        db_session.commit()
        db_session.refresh(artisan_user)

    return create_access_token({
        "sub": str(artisan_user.id),
        "role": "artisan",
        "name": artisan_user.name,
        "phone": artisan_user.phone,
    })


def test_admin_inquiries_unauthenticated_returns_401():
    """Verify accessing /admin/inquiries without token returns 401 Unauthorized."""
    response = client.get("/admin/inquiries")
    assert response.status_code == 401


def test_admin_inquiries_non_admin_token_returns_403(artisan_token: str):
    """Verify non-admin user accessing /admin/inquiries receives 403 Forbidden."""
    headers = {"Authorization": f"Bearer {artisan_token}"}
    response = client.get("/admin/inquiries", headers=headers)
    assert response.status_code == 403
    assert "Admin privileges required" in response.json()["detail"]


def test_admin_inquiries_with_valid_admin_token(admin_token: str):
    """Verify authenticated admin receives 200 with list of inquiries, pagination, and count."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    response = client.get("/admin/inquiries?limit=10&offset=0", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "inquiries" in data
    assert "total" in data
    assert isinstance(data["inquiries"], list)
