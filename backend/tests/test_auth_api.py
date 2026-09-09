import time
from datetime import timedelta
import pytest
from fastapi.testclient import TestClient

from backend.app.core.security import create_access_token, decode_access_token
from backend.app.main import app

client = TestClient(app)


def test_register_artisan_success():
    """Test user and artisan profile registration."""
    unique_phone = f"+9198{int(time.time()) % 100000000:08d}"
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
    unique_phone = f"+9197{int(time.time()) % 100000000:08d}"
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
    unique_phone = f"+9196{int(time.time()) % 100000000:08d}"
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
    unique_phone = f"+9195{int(time.time()) % 100000000:08d}"

    # 1. Send OTP
    send_res = client.post("/auth/otp/send", json={"phone": unique_phone})
    assert send_res.status_code == 200
    otp_data = send_res.json()
    assert "demo_otp" in otp_data
    otp_code = otp_data["demo_otp"]

    # 2. Verify with wrong OTP
    bad_verify = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": "000000"})
    assert bad_verify.status_code == 400

    # 3. Verify with correct OTP
    good_verify = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": otp_code})
    assert good_verify.status_code == 200
    token_data = good_verify.json()
    assert "access_token" in token_data
    assert token_data["phone"] == unique_phone


def test_get_me_profile_and_tampered_token():
    """Test JWT /auth/me authentication and rejection of tampered tokens."""
    # Generate valid token
    token = create_access_token({"sub": "1", "role": "artisan", "name": "Sunita Devi", "phone": "+919876543210"})

    # Valid request
    res = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    assert res.json()["name"] == "Sunita Devi"

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
