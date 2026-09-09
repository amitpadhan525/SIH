from fastapi import APIRouter, HTTPException, status

from backend.app.schemas.pricing import (
    PricingCalculateRequest,
    PricingCalculateResponse,
)
from backend.app.ai.pricing_engine import DynamicPricingEngine

router = APIRouter(prefix="/ai/pricing", tags=["AI Dynamic Pricing Assistant"])

pricing_engine = DynamicPricingEngine()


@router.post(
    "/calculate",
    response_model=PricingCalculateResponse,
    status_code=status.HTTP_200_OK,
    summary="Calculate fair, explainable e-commerce pricing tiers",
)
def calculate_pricing(request: PricingCalculateRequest):
    """
    Computes cost of materials, living-wage artisan labor, packaging, and craft complexity,
    generating 3 transparent pricing tiers: Fair Base, Recommended Market, and Premium Heritage.
    """
    try:
        response = pricing_engine.calculate(request)
        return response
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Pricing calculation failed: {str(e)}",
        )


@router.get(
    "/benchmarks",
    status_code=status.HTTP_200_OK,
    summary="Get reference market price benchmarks and artisan hourly rates",
)
def get_benchmarks():
    """
    Returns standard Indian artisan category price ranges and reference rates.
    """
    return {
        "categories": pricing_engine.CATEGORY_BENCHMARKS,
        "default_hourly_living_wage": 90.0,
        "recommended_work_hours_per_day": 6,
        "complexity_multipliers": {
            "low": 1.0,
            "medium": 1.15,
            "high": 1.30,
            "masterpiece": 1.50,
        },
    }
