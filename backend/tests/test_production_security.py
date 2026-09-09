import pytest
from fastapi.testclient import TestClient

from backend.app.config import Settings
from backend.app.main import app
from backend.app.config import settings

client = TestClient(app)


def test_production_secret_key_validation_fails_on_insecure_defaults():
    """Verify that in production mode, default or insecure SECRET_KEY raises ValueError."""
    insecure_settings = Settings(
        ENVIRONMENT="production",
        SECRET_KEY="sih-2026-artisan-super-secret-key-change-in-prod",
    )
    with pytest.raises(ValueError) as exc_info:
        insecure_settings.validate_production_security()
    assert "FATAL: Insecure or default SECRET_KEY" in str(exc_info.value)


def test_production_secret_key_validation_passes_on_strong_secret():
    """Verify that in production mode, strong unique 32+ char SECRET_KEY passes validation."""
    strong_settings = Settings(
        ENVIRONMENT="production",
        SECRET_KEY="a9f4c3b2e1d0987654321fedcba0987654321abcdef0123456789",
    )
    strong_settings.validate_production_security()  # Should not raise


def test_auth_demo_mode_false_hides_otp_in_response(monkeypatch):
    """Verify that when AUTH_DEMO_MODE=False, OTP is NEVER returned in send API response."""
    monkeypatch.setattr(settings, "AUTH_DEMO_MODE", False)
    response = client.post("/auth/otp/send", json={"phone": "+919876500000"})
    assert response.status_code == 200
    data = response.json()
    assert data["demo_otp"] is None
    assert "Demo code:" not in data["message"]
