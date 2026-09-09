import pytest
from fastapi.testclient import TestClient

from backend.app.main import app

client = TestClient(app)


def test_calculate_pricing_detailed_breakdown():
    """Test dynamic pricing calculation with complete cost breakdown."""
    payload = {
        "category": "Textiles",
        "cost_breakdown": {
            "material_cost": 650.00,
            "labor_hours": 16.0,
            "hourly_rate": 90.00,
            "overhead_cost": 80.00,
            "packaging_and_shipping": 70.00,
        },
        "craft_complexity": "high",
        "market_channel": "direct_to_consumer",
    }

    response = client.post("/ai/pricing/calculate", json=payload)
    assert response.status_code == 200
    data = response.json()

    # Total cost = 650 + (16*90 = 1440) + 80 + 70 = 2240.00
    assert float(data["total_cost"]) == 2240.00
    assert float(data["material_cost"]) == 650.00
    assert float(data["labor_cost"]) == 1440.00
    assert float(data["overhead_cost"]) == 80.00
    assert float(data["packaging_cost"]) == 70.00

    # Verify 3 tiers exist and increase monotonically
    tiers = data["tiers"]
    assert "fair_base" in tiers
    assert "recommended" in tiers
    assert "premium" in tiers

    fair_price = float(tiers["fair_base"]["price"])
    rec_price = float(tiers["recommended"]["price"])
    prem_price = float(tiers["premium"]["price"])

    assert fair_price < rec_price < prem_price
    assert fair_price > 2240.00  # Must be profitable above base cost
    assert tiers["fair_base"]["margin_percent"] == 25.0
    assert tiers["recommended"]["margin_percent"] == 45.0
    assert tiers["premium"]["margin_percent"] == 75.0

    # Verify profit
    assert float(tiers["recommended"]["artisan_profit"]) > 0

    # Verify explanation and benchmark range
    assert "₹" in data["pricing_explanation"]
    assert "Textiles" in data["category_benchmark_range"] or "Handloom" in data["category_benchmark_range"]


def test_calculate_pricing_with_artisan_stated_days():
    """Test labor hours auto-calculation from artisan-spoken days (e.g. 3 days = 18 hrs)."""
    payload = {
        "category": "Pottery",
        "cost_breakdown": {
            "material_cost": 150.00,
            "labor_hours": 0.0,
            "hourly_rate": 80.00,
            "overhead_cost": 40.00,
            "packaging_and_shipping": 50.00,
        },
        "artisan_stated_days": 3,
        "craft_complexity": "medium",
    }

    response = client.post("/ai/pricing/calculate", json=payload)
    assert response.status_code == 200
    data = response.json()

    # 3 days * 6 hrs/day = 18 hrs @ 80/hr = 1440.00
    assert float(data["labor_cost"]) == 1440.00
    assert float(data["total_cost"]) == 150.00 + 1440.00 + 40.00 + 50.00
    assert float(data["suggested_price"]) > float(data["total_cost"])


def test_calculate_pricing_default_fallback():
    """Test calculator gracefully provides standard fallback when inputs are 0."""
    payload = {
        "category": "Handicraft",
        "cost_breakdown": {},
    }

    response = client.post("/ai/pricing/calculate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert float(data["total_cost"]) > 0
    assert float(data["suggested_price"]) > 0


def test_get_pricing_benchmarks():
    """Test benchmark reference rates endpoint."""
    response = client.get("/ai/pricing/benchmarks")
    assert response.status_code == 200
    data = response.json()
    assert "categories" in data
    assert "textiles" in data["categories"]
    assert data["default_hourly_living_wage"] >= 80.0
