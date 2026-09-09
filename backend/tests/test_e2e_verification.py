import time
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from backend.app.main import app
from backend.app.db.session import SessionLocal
from backend.app.models.user import User
from backend.app.models.artisan import Artisan
from backend.app.models.product import Product

client = TestClient(app)


def test_real_end_to_end_auth_flow():
    """
    Real End-to-End Test covering:
    1. Fresh phone OTP request
    2. Zero-cost demo OTP retrieval
    3. Server-side verification & single-use invalidation
    4. Auto-provisioning of User and Artisan in DB with incomplete profile
    5. First-time Complete Profile submission via /auth/me/profile
    6. JWT issuance and profile retrieval via /auth/me showing is_profile_complete=True
    7. Protected product creation with authenticated artisan identity
    8. Ownership verification in DB
    9. Attempt protected product creation without JWT -> 401 Unauthorized
    10. IDOR protection: Artisan B cannot modify Artisan A's product -> 403 Forbidden
    11. Repeat login with same phone -> Reuses existing User/Artisan without duplicates and preserves complete profile
    """
    timestamp = int(time.time() * 1000) % 100000000
    phone_a = f"+9198{timestamp:08d}"

    # Step 1: Request OTP for phone_a
    send_res_a = client.post("/auth/otp/send", json={"phone": phone_a})
    assert send_res_a.status_code == 200
    send_data_a = send_res_a.json()
    assert "demo_otp" in send_data_a
    demo_otp_a = send_data_a["demo_otp"]
    assert len(demo_otp_a) == 6

    # Step 2: Attempt wrong OTP
    bad_verify = client.post("/auth/otp/verify", json={"phone": phone_a, "otp": "000000"})
    assert bad_verify.status_code == 400

    # Step 3: Verify with correct OTP (first time login -> is_profile_complete is False)
    verify_res_a = client.post("/auth/otp/verify", json={"phone": phone_a, "otp": demo_otp_a})
    assert verify_res_a.status_code == 200
    auth_data_a = verify_res_a.json()
    assert "access_token" in auth_data_a
    token_a = auth_data_a["access_token"]
    user_id_a = auth_data_a["user_id"]
    artisan_id_a = auth_data_a["artisan_id"]
    assert artisan_id_a is not None
    assert auth_data_a["is_profile_complete"] is False

    # Step 4: Verify single-use OTP invalidation (reuse must fail)
    reuse_res = client.post("/auth/otp/verify", json={"phone": phone_a, "otp": demo_otp_a})
    assert reuse_res.status_code == 400

    # Step 5: Complete Profile for first-time artisan
    profile_payload = {
        "full_name": "Gita Meher",
        "craft_category": "Handloom",
        "state": "Odisha",
        "district": "Bargarh",
        "preferred_language": "Odia",
        "artisan_name": "Meher Weaves Studio",
        "artisan_type": "Individual",
        "experience_years": 12,
        "description": "Authentic tie and dye Ikat Sambalpuri textiles.",
    }
    update_res = client.put("/auth/me/profile", json=profile_payload, headers={"Authorization": f"Bearer {token_a}"})
    assert update_res.status_code == 200
    assert update_res.json()["is_profile_complete"] is True
    assert update_res.json()["name"] == "Gita Meher"

    # Step 6: Check authenticated profile via /auth/me
    me_res = client.get("/auth/me", headers={"Authorization": f"Bearer {token_a}"})
    assert me_res.status_code == 200
    assert me_res.json()["user_id"] == user_id_a
    assert me_res.json()["artisan_id"] == artisan_id_a
    assert me_res.json()["is_profile_complete"] is True
    assert me_res.json()["craft_category"] == "Handloom"

    # Step 7: Create Product as Artisan A (ownership derived from JWT)
    prod_payload = {
        "name": "E2E Dokra Bell",
        "category": "Metalwork",
        "material": "Brass",
        "price": "850.00",
        "status": "published",
    }
    prod_res = client.post("/products", json=prod_payload, headers={"Authorization": f"Bearer {token_a}"})
    assert prod_res.status_code == 201
    product_a = prod_res.json()
    product_id_a = product_a["id"]
    assert product_a["artisan_id"] == artisan_id_a
    assert product_a["name"] == "E2E Dokra Bell"

    # Step 8: Attempt unauthenticated product creation -> 401
    anon_prod_res = client.post("/products", json=prod_payload)
    assert anon_prod_res.status_code == 401

    # Step 9: Authenticate Artisan B
    phone_b = f"+9197{timestamp:08d}"
    send_res_b = client.post("/auth/otp/send", json={"phone": phone_b})
    demo_otp_b = send_res_b.json()["demo_otp"]
    verify_res_b = client.post("/auth/otp/verify", json={"phone": phone_b, "otp": demo_otp_b})
    token_b = verify_res_b.json()["access_token"]
    artisan_id_b = verify_res_b.json()["artisan_id"]
    assert artisan_id_b != artisan_id_a

    # Step 10: IDOR Protection - Artisan B attempts to delete Artisan A's product -> 403 Forbidden
    del_idor_res = client.delete(f"/products/{product_id_a}", headers={"Authorization": f"Bearer {token_b}"})
    assert del_idor_res.status_code == 403

    # Step 11: Repeat Login with phone_a -> Must reuse same User & Artisan and preserve profile
    repeat_send = client.post("/auth/otp/send", json={"phone": phone_a})
    repeat_otp = repeat_send.json()["demo_otp"]
    repeat_verify = client.post("/auth/otp/verify", json={"phone": phone_a, "otp": repeat_otp})
    assert repeat_verify.status_code == 200
    repeat_data = repeat_verify.json()
    assert repeat_data["user_id"] == user_id_a
    assert repeat_data["artisan_id"] == artisan_id_a
    assert repeat_data["name"] == "Gita Meher"
    assert repeat_data["is_profile_complete"] is True

    # Verify Database source of truth directly
    with SessionLocal() as db:
        user_count = db.query(User).filter(User.phone == phone_a).count()
        artisan_count = db.query(Artisan).filter(Artisan.user_id == user_id_a).count()
        product_record = db.get(Product, product_id_a)
        artisan_record = db.get(Artisan, artisan_id_a)

        assert user_count == 1, "Duplicate user was created!"
        assert artisan_count == 1, "Duplicate artisan was created!"
        assert artisan_record.is_profile_complete is True
        assert artisan_record.craft_category == "Handloom"
        assert artisan_record.district == "Bargarh"
        assert product_record is not None
        assert product_record.artisan_id == artisan_id_a
