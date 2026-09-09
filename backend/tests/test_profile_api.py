import time
import pytest
from fastapi.testclient import TestClient

from backend.app.core.security import create_access_token
from backend.app.db.session import SessionLocal
from backend.app.models.artisan import Artisan
from backend.app.models.user import User
from backend.app.main import app

client = TestClient(app)


def test_first_otp_login_creates_incomplete_profile():
    """Test first OTP login provisions User & Artisan marked as incomplete."""
    unique_phone = f"+9191{int(time.time() * 1000) % 100000000:08d}"
    
    # 1. Send OTP
    send_res = client.post("/auth/otp/send", json={"phone": unique_phone})
    assert send_res.status_code == 200
    demo_otp = send_res.json()["demo_otp"]
    assert demo_otp is not None

    # 2. Verify OTP
    verify_res = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": demo_otp})
    assert verify_res.status_code == 200
    data = verify_res.json()
    assert "access_token" in data
    assert data["phone"] == unique_phone
    assert data["is_profile_complete"] is False
    assert data["user_id"] is not None
    assert data["artisan_id"] is not None


def test_complete_profile_success_and_persistence():
    """Test submitting required and optional profile information saves to database."""
    unique_phone = f"+9192{int(time.time() * 1000) % 100000000:08d}"
    
    # Send & Verify OTP
    send_res = client.post("/auth/otp/send", json={"phone": unique_phone})
    demo_otp = send_res.json()["demo_otp"]
    verify_res = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": demo_otp})
    token = verify_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Complete Profile
    profile_payload = {
        "full_name": "Radha Charan Meher",
        "craft_category": "Handloom",
        "state": "Odisha",
        "district": "Bargarh",
        "preferred_language": "Odia",
        "artisan_name": "Sambalpuri Heritage Weaves",
        "artisan_type": "Master Weaver",
        "experience_years": 25,
        "description": "Traditional tie-and-dye Ikat Sambalpuri cotton and silk sarees."
    }

    update_res = client.put("/auth/me/profile", json=profile_payload, headers=headers)
    assert update_res.status_code == 200
    updated = update_res.json()
    assert updated["name"] == "Radha Charan Meher"
    assert updated["is_profile_complete"] is True
    assert updated["craft_category"] == "Handloom"
    assert updated["state"] == "Odisha"
    assert updated["district"] == "Bargarh"
    assert updated["preferred_language"] == "Odia"
    assert updated["artisan_name"] == "Sambalpuri Heritage Weaves"
    assert updated["experience_years"] == 25
    assert "Ikat Sambalpuri" in updated["description"]

    # Verify GET /auth/me returns updated complete state
    me_res = client.get("/auth/me", headers=headers)
    assert me_res.status_code == 200
    me_data = me_res.json()
    assert me_data["name"] == "Radha Charan Meher"
    assert me_data["is_profile_complete"] is True
    assert me_data["craft_category"] == "Handloom"


def test_repeat_otp_login_preserves_completed_profile_and_no_duplicates():
    """Test logging in again with the same phone number preserves profile and does not duplicate records."""
    unique_phone = f"+9193{int(time.time() * 1000) % 100000000:08d}"
    
    # First Login
    s1 = client.post("/auth/otp/send", json={"phone": unique_phone})
    v1 = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": s1.json()["demo_otp"]})
    token1 = v1.json()["access_token"]
    user_id_1 = v1.json()["user_id"]
    artisan_id_1 = v1.json()["artisan_id"]

    # Complete Profile
    client.put("/auth/me/profile", json={
        "full_name": "Rameshwar Sahoo",
        "craft_category": "Pottery",
        "state": "Rajasthan",
        "district": "Jaipur",
        "preferred_language": "Hindi",
    }, headers={"Authorization": f"Bearer {token1}"})

    # Second Login with SAME phone number
    s2 = client.post("/auth/otp/send", json={"phone": unique_phone})
    v2 = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": s2.json()["demo_otp"]})
    assert v2.status_code == 200
    v2_data = v2.json()
    
    # Verify same IDs and preserved completed profile
    assert v2_data["user_id"] == user_id_1
    assert v2_data["artisan_id"] == artisan_id_1
    assert v2_data["name"] == "Rameshwar Sahoo"
    assert v2_data["is_profile_complete"] is True
    assert v2_data["craft_category"] == "Pottery"
    assert v2_data["state"] == "Rajasthan"


def test_profile_update_validation_errors():
    """Test validation errors for required and numeric fields."""
    unique_phone = f"+9194{int(time.time() * 1000) % 100000000:08d}"
    s = client.post("/auth/otp/send", json={"phone": unique_phone})
    v = client.post("/auth/otp/verify", json={"phone": unique_phone, "otp": s.json()["demo_otp"]})
    headers = {"Authorization": f"Bearer {v.json()['access_token']}"}

    # 1. Missing full_name
    r1 = client.put("/auth/me/profile", json={
        "craft_category": "Pottery",
        "state": "Odisha",
        "district": "Puri",
    }, headers=headers)
    assert r1.status_code == 422

    # 2. Negative experience_years
    r2 = client.put("/auth/me/profile", json={
        "full_name": "Test Artisan",
        "craft_category": "Pottery",
        "state": "Odisha",
        "district": "Puri",
        "experience_years": -5,
    }, headers=headers)
    assert r2.status_code == 422


def test_unauthenticated_profile_update_returns_401():
    """Test updating profile without JWT token returns 401."""
    res = client.put("/auth/me/profile", json={
        "full_name": "Attacker",
        "craft_category": "Jewellery",
        "state": "Delhi",
        "district": "New Delhi",
    })
    assert res.status_code == 401
