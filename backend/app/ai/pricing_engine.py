from decimal import Decimal, ROUND_HALF_UP
from typing import Dict

from backend.app.schemas.pricing import (
    CostBreakdownInput,
    PriceTier,
    PricingCalculateRequest,
    PricingCalculateResponse,
)


class DynamicPricingEngine:
    """
    Explainable Artisan Pricing Engine.
    Ensures fair living wages for rural artisans while calculating competitive market prices.
    """

    CATEGORY_BENCHMARKS = {
        "textiles": {"min": 800, "max": 12000, "unit": "per piece / saree", "label": "Handloom & Textiles"},
        "handloom": {"min": 800, "max": 12000, "unit": "per piece / saree", "label": "Handloom & Textiles"},
        "pottery": {"min": 250, "max": 4500, "unit": "per set / piece", "label": "Clay & Terracotta"},
        "terracotta": {"min": 250, "max": 4500, "unit": "per set / piece", "label": "Clay & Terracotta"},
        "metalwork": {"min": 650, "max": 18000, "unit": "per sculpture / lamp", "label": "Brass & Dokra Metalcraft"},
        "dokra": {"min": 650, "max": 18000, "unit": "per sculpture / lamp", "label": "Brass & Dokra Metalcraft"},
        "paintings": {"min": 500, "max": 15000, "unit": "per folk art painting", "label": "Traditional Folk Paintings"},
        "woodwork": {"min": 400, "max": 9500, "unit": "per carving / toy", "label": "Woodcraft & Carvings"},
        "handicraft": {"min": 300, "max": 8000, "unit": "per artisanal product", "label": "General Handicrafts"},
    }

    COMPLEXITY_MULTIPLIERS = {
        "low": Decimal("1.00"),
        "medium": Decimal("1.15"),
        "high": Decimal("1.30"),
        "masterpiece": Decimal("1.50"),
    }

    def _round_to_practical_price(self, price: Decimal) -> Decimal:
        """Rounds price to nearest ₹10 for clean, practical consumer e-commerce pricing."""
        val = float(price)
        if val <= 100:
            rounded = round(val / 5.0) * 5.0
        elif val <= 1000:
            rounded = round(val / 10.0) * 10.0
        else:
            rounded = round(val / 50.0) * 50.0
        return Decimal(str(int(rounded))).quantize(Decimal("1.00"))

    def calculate(self, request: PricingCalculateRequest) -> PricingCalculateResponse:
        breakdown: CostBreakdownInput = request.cost_breakdown

        # 1. Clean & clamp inputs (handle negatives gracefully)
        material_cost = max(Decimal("0.00"), breakdown.material_cost)
        overhead_cost = max(Decimal("0.00"), breakdown.overhead_cost).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        packaging_cost = max(Decimal("0.00"), breakdown.packaging_and_shipping).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        hourly_rate = breakdown.hourly_rate if breakdown.hourly_rate > 0 else Decimal("90.00")

        # Labor calculation: if hours not given but days are stated, convert days to hours (6 hrs/day)
        labor_hours = max(Decimal("0.00"), breakdown.labor_hours)
        if labor_hours <= Decimal("0.00") and request.artisan_stated_days and request.artisan_stated_days > 0:
            labor_hours = Decimal(str(request.artisan_stated_days * 6))

        # Default fallback if no hours or materials were entered: minimal default production unit
        if material_cost <= Decimal("0.00") and labor_hours <= Decimal("0.00"):
            material_cost = Decimal("200.00")
            labor_hours = Decimal("4.00")

        labor_cost = (labor_hours * hourly_rate).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

        total_production_cost = (material_cost + labor_cost + overhead_cost + packaging_cost).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )

        # 2. Complexity factor
        complexity_key = request.craft_complexity.lower().strip()
        complexity_multiplier = self.COMPLEXITY_MULTIPLIERS.get(complexity_key, Decimal("1.15"))

        # Base adjusted cost factoring artisan skill
        adjusted_base = total_production_cost * complexity_multiplier

        # 3. Calculate 3 Tiers with practical consumer rounding
        # Tier 1: Fair Base (25% profit margin) - Minimum price ensuring fair living wage
        margin_fair = 0.25
        raw_fair = adjusted_base * Decimal("1.25")
        fair_price = max(total_production_cost + Decimal("50.00"), self._round_to_practical_price(raw_fair))
        profit_fair = (fair_price - total_production_cost).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

        # Tier 2: Recommended Market (45% profit margin) - Optimal e-commerce sweet spot
        margin_rec = 0.45
        raw_rec = adjusted_base * Decimal("1.45")
        rec_price = max(fair_price + Decimal("50.00"), self._round_to_practical_price(raw_rec))
        profit_rec = (rec_price - total_production_cost).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

        # Tier 3: Premium Heritage (75% profit margin) - High-end exhibitions, exports, bespoke collections
        margin_prem = 0.75
        raw_prem = adjusted_base * Decimal("1.75")
        prem_price = max(rec_price + Decimal("100.00"), self._round_to_practical_price(raw_prem))
        profit_prem = (prem_price - total_production_cost).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

        tiers: Dict[str, PriceTier] = {
            "fair_base": PriceTier(
                name="Fair Base Price",
                price=fair_price,
                margin_percent=margin_fair * 100,
                artisan_profit=profit_fair,
                rationale=(
                    f"Covers all raw materials (₹{material_cost}), guarantees ₹{hourly_rate}/hr "
                    f"for {labor_hours} hours of dedicated handwork, plus 25% safety margin."
                ),
            ),
            "recommended": PriceTier(
                name="Recommended E-Commerce Price",
                price=rec_price,
                margin_percent=margin_rec * 100,
                artisan_profit=profit_rec,
                rationale=(
                    f"Optimal online market price. Delivers healthy ₹{profit_rec} profit per item "
                    "while remaining competitive against commercial machine alternatives."
                ),
            ),
            "premium": PriceTier(
                name="Premium Heritage / Export",
                price=prem_price,
                margin_percent=margin_prem * 100,
                artisan_profit=profit_prem,
                rationale=(
                    "Ideal for art collectors, exhibitions, and export markets that value authentic "
                    "master artisan heritage and intricate handcrafting."
                ),
            ),
        }

        # Benchmark Range
        cat_key = request.category.lower()
        matched_benchmark = self.CATEGORY_BENCHMARKS.get("handicraft")
        for k, bench in self.CATEGORY_BENCHMARKS.items():
            if k in cat_key:
                matched_benchmark = bench
                break

        benchmark_str = f"{matched_benchmark['label']}: ₹{matched_benchmark['min']} – ₹{matched_benchmark['max']} ({matched_benchmark['unit']})"

        explanation = (
            f"Your total cost of production is ₹{total_production_cost} (Materials: ₹{material_cost} + "
            f"Labor: {labor_hours} hrs @ ₹{hourly_rate}/hr = ₹{labor_cost} + Overhead & Packaging: ₹{overhead_cost + packaging_cost}). "
            f"We recommend listing at ₹{rec_price} to take home ₹{profit_rec} in pure profit."
        )

        return PricingCalculateResponse(
            total_cost=total_production_cost,
            material_cost=material_cost,
            labor_cost=labor_cost,
            overhead_cost=overhead_cost,
            packaging_cost=packaging_cost,
            suggested_price=rec_price,
            tiers=tiers,
            pricing_explanation=explanation,
            category_benchmark_range=benchmark_str,
        )
