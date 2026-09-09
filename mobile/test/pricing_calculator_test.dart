import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_mobile/screens/pricing_calculator/pricing_calculator_screen.dart';
import 'package:artisan_mobile/services/product_service.dart';

class MockPricingProductService extends ProductService {
  @override
  Future<Map<String, dynamic>> calculatePricing(Map<String, dynamic> request) async {
    return {
      'total_cost': '1110.00',
      'material_cost': '350.00',
      'labor_cost': '720.00',
      'overhead_cost': '40.00',
      'packaging_cost': '50.00',
      'suggested_price': '1850.00',
      'category_benchmark_range': 'Handloom & Textiles: ₹800 – ₹12000 (per piece / saree)',
      'pricing_explanation': 'Your total production cost is ₹1110.00. We recommend listing at ₹1850.00.',
      'tiers': {
        'fair_base': {
          'name': 'Fair Base Price',
          'price': '1595.00',
          'margin_percent': 25.0,
          'artisan_profit': '485.00',
          'rationale': 'Covers all materials and living wage labor + 25% margin.',
        },
        'recommended': {
          'name': 'Recommended E-Commerce Price',
          'price': '1850.00',
          'margin_percent': 45.0,
          'artisan_profit': '740.00',
          'rationale': 'Optimal e-commerce market price balancing profit and buyer demand.',
        },
        'premium': {
          'name': 'Premium Heritage / Export',
          'price': '2230.00',
          'margin_percent': 75.0,
          'artisan_profit': '1120.00',
          'rationale': 'Ideal for bespoke craft collectors and export markets.',
        },
      },
    };
  }
}

void main() {
  group('PricingCalculatorScreen Widget Tests', () {
    testWidgets('Renders input fields, benchmark banner, and 3 pricing tiers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PricingCalculatorScreen(
            category: 'Textiles',
            productService: MockPricingProductService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dynamic Pricing Assistant'), findsOneWidget);
      expect(find.text('Cost & Labor Calculator (Textiles)'), findsOneWidget);
      expect(find.text('Raw Materials Cost (₹)'), findsOneWidget);
      expect(find.text('Work Hours Spent'), findsOneWidget);
      expect(find.text('Living Wage Rate'), findsOneWidget);

      // Benchmark range
      expect(find.textContaining('Market Benchmark Range:'), findsOneWidget);

      // 3 Price Tiers
      expect(find.text('Fair Base Price'), findsOneWidget);
      expect(find.text('Recommended E-Commerce Price'), findsOneWidget);
      expect(find.text('Premium Heritage / Export'), findsOneWidget);
    });

    testWidgets('Tapping a tier card selects it and allows applying price', (tester) async {
      String? returnedPrice;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  final res = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PricingCalculatorScreen(
                        category: 'Textiles',
                        productService: MockPricingProductService(),
                      ),
                    ),
                  );
                  returnedPrice = res;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open screen
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Scroll to Fair Base Price
      await tester.ensureVisible(find.text('Fair Base Price'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fair Base Price'));
      await tester.pumpAndSettle();

      // Apply button
      await tester.ensureVisible(find.text('Apply Selected Price to Product'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Selected Price to Product'));
      await tester.pumpAndSettle();

      // Verify returned price was Fair Base Price (1595.00)
      expect(returnedPrice, '1595.00');
    });
  });
}
