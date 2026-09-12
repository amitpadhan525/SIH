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


def test_dynamic_pricing_distinct_products_produce_distinct_prices():
    """Test that Product A and Product B with different hours/materials produce different prices."""
    # Product A: Sambalpuri Saree (High labor, high materials)
    payload_a = {
        "category": "Handloom & Textiles",
        "cost_breakdown": {
            "material_cost": 850.00,
            "labor_hours": 36.0,
            "hourly_rate": 90.00,
            "overhead_cost": 100.00,
            "packaging_and_shipping": 80.00,
        },
        "craft_complexity": "high",
    }
    res_a = client.post("/ai/pricing/calculate", json=payload_a)
    assert res_a.status_code == 200
    price_a = float(res_a.json()["suggested_price"])

    # Product B: Terracotta Diya (Low labor, low materials)
    payload_b = {
        "category": "Clay & Terracotta Pottery",
        "cost_breakdown": {
            "material_cost": 80.00,
            "labor_hours": 3.0,
            "hourly_rate": 90.00,
            "overhead_cost": 20.00,
            "packaging_and_shipping": 30.00,
        },
        "craft_complexity": "low",
    }
    res_b = client.post("/ai/pricing/calculate", json=payload_b)
    assert res_b.status_code == 200
    price_b = float(res_b.json()["suggested_price"])

    # Mandatory assertions:
    assert price_a != price_b
    assert price_a > price_b * 3  # Product A is significantly higher cost
    assert price_a != 2451.23  # Verify hardcoded 2451.23 is not produced
    assert price_b != 2451.23


def test_negative_costs_rejected_by_schema():
    """Test that negative costs are rejected at API validation boundary with 422."""
    payload = {
        "category": "Handicraft",
        "cost_breakdown": {
            "material_cost": -50.00,
            "labor_hours": 5.0,
        },
    }
    response = client.post("/ai/pricing/calculate", json=payload)
    assert response.status_code == 422


def test_zero_costs_handled_gracefully_with_baseline():
    """Test that zero costs provide a safe living baseline calculation."""
    payload = {
        "category": "Handicraft",
        "cost_breakdown": {
            "material_cost": 0.00,
            "labor_hours": 0.0,
            "overhead_cost": 0.00,
            "packaging_and_shipping": 0.00,
        },
    }
    response = client.post("/ai/pricing/calculate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert float(data["total_cost"]) > 0
    assert float(data["suggested_price"]) > float(data["total_cost"])
