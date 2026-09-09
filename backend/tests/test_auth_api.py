import time
from datetime import timedelta
import pytest
from fastapi.testclient import TestClient

from backend.app.config import settings
from backend.app.core.security import create_access_token, decode_access_token
from backend.app.db.session import SessionLocal
from backend.app.models.artisan import Artisan
from backend.app.models.product import Product
from backend.app.models.user import User
from backend.app.main import app

client = TestClient(app)


def test_register_artisan_success():
    """Test user and artisan profile registration."""
    unique_phone = f"+9198{int(time.time() * 1000) % 100000000:08d}"
    payload = {
        "name": "Kavita Sharma",
        "phone": unique_phone,
        "password": "SecurePassword123",
        "role": "artisan",
        "language": "hi",
        "location": "Jaipur, Rajasthan",
        "craft_type": "Blue Pottery",
    }

    response = client.post("/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert data["name"] == "Kavita Sharma"
    assert data["role"] == "artisan"
    assert data["artisan_id"] is not None


def test_register_duplicate_phone_fails():
    """Test phone uniqueness constraint at registration."""
    unique_phone = f"+9197{int(time.time() * 1000) % 100000000:08d}"
    payload = {
        "name": "First User",
        "phone": unique_phone,
        "password": "password123",
        "role": "artisan",
    }
    res1 = client.post("/auth/register", json=payload)
    assert res1.status_code == 201

    # Attempt duplicate
    res2 = client.post("/auth/register", json=payload)
    assert res2.status_code == 400


def test_login_success_and_invalid_credentials():
    """Test login with valid and invalid credentials."""
    unique_phone = f"+9196{int(time.time() * 1000) % 100000000:08d}"
    reg_payload = {
        "name": "Devi Lal",
        "phone": unique_phone,
        "password": "CorrectPassword",
        "role": "artisan",
    }
    client.post("/auth/register", json=reg_payload)

    # Valid login
    login_res = client.post("/auth/login", json={"phone": unique_phone, "password": "CorrectPassword"})
    assert login_res.status_code == 200
    assert "access_token" in login_res.json()

    # Invalid login
    bad_login = client.post("/auth/login", json={"phone": "+919000000000", "password": "WrongPassword"})
    assert bad_login.status_code == 401


def test_otp_send_and_verify_flow():
    """Test phone OTP sending and verification."""
    unique_phone = f"+9195{int(time.time() * 1000) % 100000000:08d}"

    # 1. Send OTP
    send_res = client.post("/auth/otp/send", json={"phone": unique_phone})
    assert send_res.status_code == 200
    otp_data = send_res.json()
    assert "demo_otp" in otp_data
    otp_code = otp_data["demo_otp"]
    assert len(otp_code) == 6

    # 2. Verify with wrong OTP
    bad_verify = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": "000000"})
    assert bad_verify.status_code == 400

    # 3. Verify with correct OTP
    good_verify = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": otp_code})
    assert good_verify.status_code == 200
    token_data = good_verify.json()
    assert "access_token" in token_data
    assert token_data["phone"] == unique_phone
    assert token_data["artisan_id"] is not None


def test_invalid_phone_validation():
    """Test rejection of invalid phone numbers."""
    res1 = client.post("/auth/otp/send", json={"phone": "123"})
    assert res1.status_code == 422

    res2 = client.post("/auth/otp/send", json={"phone": ""})
    assert res2.status_code == 422


def test_otp_single_use():
    """Test that OTP cannot be reused after successful verification."""
    unique_phone = f"+9194{int(time.time() * 1000) % 100000000:08d}"
    send_res = client.post("/auth/otp/send", json={"phone": unique_phone})
    otp_code = send_res.json()["demo_otp"]

    # First verify succeeds
    res1 = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": otp_code})
    assert res1.status_code == 200

    # Second verify with same OTP fails
    res2 = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": otp_code})
    assert res2.status_code == 400


def test_new_otp_invalidates_previous_otp():
    """Test requesting a new OTP invalidates previous OTP."""
    unique_phone = f"+9193{int(time.time() * 1000) % 100000000:08d}"
    send1 = client.post("/auth/otp/send", json={"phone": unique_phone})
    otp1 = send1.json()["demo_otp"]

    send2 = client.post("/auth/otp/send", json={"phone": unique_phone})
    otp2 = send2.json()["demo_otp"]

    # Old OTP must fail
    bad_res = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": otp1})
    assert bad_res.status_code == 400

    # New OTP must succeed
    good_res = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": otp2})
    assert good_res.status_code == 200


def test_repeat_login_does_not_duplicate_user():
    """Test repeat logins reuse the existing User and Artisan records."""
    unique_phone = f"+9192{int(time.time() * 1000) % 100000000:08d}"

    # First login
    send1 = client.post("/auth/otp/send", json={"phone": unique_phone})
    otp1 = send1.json()["demo_otp"]
    res1 = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": otp1})
    assert res1.status_code == 200
    user_id_1 = res1.json()["user_id"]
    artisan_id_1 = res1.json()["artisan_id"]

    # Second login
    send2 = client.post("/auth/otp/send", json={"phone": unique_phone})
    otp2 = send2.json()["demo_otp"]
    res2 = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": otp2})
    assert res2.status_code == 200
    user_id_2 = res2.json()["user_id"]
    artisan_id_2 = res2.json()["artisan_id"]

    assert user_id_1 == user_id_2
    assert artisan_id_1 == artisan_id_2

    # Verify directly in DB
    db = SessionLocal()
    users_count = db.query(User).filter(User.phone == unique_phone).count()
    artisans_count = db.query(Artisan).filter(Artisan.user_id == user_id_1).count()
    db.close()

    assert users_count == 1
    assert artisans_count == 1


def test_get_me_profile_and_tampered_token():
    """Test JWT /auth/me authentication and rejection of tampered tokens."""
    # Create user in DB first
    unique_phone = f"+9191{int(time.time() * 1000) % 100000000:08d}"
    send_res = client.post("/auth/otp/send", json={"phone": unique_phone})
    token_res = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": send_res.json()["demo_otp"]})
    token = token_res.json()["access_token"]
    user_id = token_res.json()["user_id"]

    # Valid request
    res = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    assert res.json()["user_id"] == user_id

    # Missing header
    res_no_auth = client.get("/auth/me")
    assert res_no_auth.status_code == 401

    # Tampered signature
    tampered_token = token[:-5] + "XXXXX"
    res_tampered = client.get("/auth/me", headers={"Authorization": f"Bearer {tampered_token}"})
    assert res_tampered.status_code == 401


def test_jwt_expiration():
    """Test expired JWT token is rejected."""
    expired_token = create_access_token(
        {"sub": "1", "role": "artisan", "name": "Test User"},
        expires_delta=timedelta(seconds=-10),  # expired 10 seconds ago
    )
    res = client.get("/auth/me", headers={"Authorization": f"Bearer {expired_token}"})
    assert res.status_code == 401


def test_protected_product_endpoints_and_ownership():
    """Test that creating and modifying products requires JWT authentication and enforces ownership."""
    # 1. Unauthenticated product creation rejected
    anon_res = client.post("/products", json={"name": "Clay Pot", "category": "Pottery", "price": 150})
    assert anon_res.status_code == 401

    # 2. Authenticate Artisan A
    phone_a = f"+9190{int(time.time() * 1000) % 100000000:08d}"
    send_a = client.post("/auth/otp/send", json={"phone": phone_a})
    res_a = client.post("/auth/otp/verify", json={"phone": phone_a, "otp": send_a.json()["demo_otp"]})
    token_a = res_a.json()["access_token"]
    artisan_id_a = res_a.json()["artisan_id"]

    # Artisan A creates product
    prod_res = client.post(
        "/products",
        json={"name": "Handmade Clay Vase", "category": "Pottery", "price": 450},
        headers={"Authorization": f"Bearer {token_a}"},
    )
    assert prod_res.status_code == 201
    prod_data = prod_res.json()
    assert prod_data["artisan_id"] == artisan_id_a
    product_id = prod_data["id"]

    # 3. Authenticate Artisan B
    phone_b = f"+9189{int(time.time() * 1000) % 100000000:08d}"
    send_b = client.post("/auth/otp/send", json={"phone": phone_b})
    res_b = client.post("/auth/otp/verify", json={"phone": phone_b, "otp": send_b.json()["demo_otp"]})
    token_b = res_b.json()["access_token"]

    # Artisan B attempts to update Artisan A's product -> 403 Forbidden (IDOR Protection)
    update_res = client.put(
        f"/products/{product_id}",
        json={"name": "Hacked Vase"},
        headers={"Authorization": f"Bearer {token_b}"},
    )
    assert update_res.status_code == 403

    # Artisan B attempts to delete Artisan A's product -> 403 Forbidden
    del_res = client.delete(
        f"/products/{product_id}",
        headers={"Authorization": f"Bearer {token_b}"},
    )
    assert del_res.status_code == 403

    # Artisan A successfully updates own product
    good_update = client.put(
        f"/products/{product_id}",
        json={"name": "Artisan A Vase Updated", "price": 500},
        headers={"Authorization": f"Bearer {token_a}"},
    )
    assert good_update.status_code == 200
    assert good_update.json()["name"] == "Artisan A Vase Updated"
