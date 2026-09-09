from decimal import Decimal
from typing import Dict, List, Optional
from pydantic import BaseModel, Field


class CostBreakdownInput(BaseModel):
    material_cost: Decimal = Field(default=Decimal("0.00"), ge=0, description="Total raw materials cost in INR")
    labor_hours: Decimal = Field(default=Decimal("0.00"), ge=0, description="Artisan working hours spent")
    hourly_rate: Decimal = Field(default=Decimal("90.00"), ge=0, description="Artisan hourly living wage rate in INR")
    overhead_cost: Decimal = Field(default=Decimal("0.00"), ge=0, description="Electricity, kiln, tool depreciation")
    packaging_and_shipping: Decimal = Field(default=Decimal("50.00"), ge=0, description="Eco-friendly packaging and transit buffer")


class PricingCalculateRequest(BaseModel):
    category: str = Field(default="Handicraft", description="Product category (Textiles, Pottery, Metalwork, etc.)")
    cost_breakdown: CostBreakdownInput = Field(default_factory=CostBreakdownInput)
    craft_complexity: str = Field(default="medium", description="Complexity: 'low', 'medium', 'high', 'masterpiece'")
    market_channel: str = Field(default="direct_to_consumer", description="'direct_to_consumer', 'wholesale_b2b', 'export'")
    artisan_stated_days: Optional[int] = Field(None, ge=1, description="Days taken if extracted from speech")


class PriceTier(BaseModel):
    name: str = Field(..., description="Tier name: Fair Base, Recommended Market, Premium Heritage")
    price: Decimal = Field(..., description="Calculated retail price in INR")
    margin_percent: float = Field(..., description="Profit margin percentage above total production cost")
    artisan_profit: Decimal = Field(..., description="Net artisan profit above labor and materials in INR")
    rationale: str = Field(..., description="Clear explanation for this price point")


class PricingCalculateResponse(BaseModel):
    total_cost: Decimal = Field(..., description="Base cost of production (materials + labor + overhead + packaging)")
    material_cost: Decimal
    labor_cost: Decimal
    overhead_cost: Decimal
    packaging_cost: Decimal
    suggested_price: Decimal = Field(..., description="AI Recommended retail price")
    tiers: Dict[str, PriceTier] = Field(..., description="3 price tiers: 'fair_base', 'recommended', 'premium'")
    pricing_explanation: str = Field(..., description="Artisan-friendly transparent explanation in simple terms")
    category_benchmark_range: str = Field(..., description="Typical market price range for this craft category")
