import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_mobile/screens/inquiries/inquiries_screen.dart';
import 'package:artisan_mobile/services/product_service.dart';

class MockInquiryProductService extends ProductService {
  final bool returnEmpty;

  MockInquiryProductService({this.returnEmpty = false});

  @override
  Future<List<Map<String, dynamic>>> getArtisanInquiries(int artisanId, {String? status}) async {
    if (returnEmpty) return [];

    return [
      {
        'id': 101,
        'product_id': 1,
        'product_name': 'Handwoven Sambalpuri Saree',
        'product_price': '4500.00',
        'product_image_url': null,
        'buyer_name': 'Crafts of India Exports',
        'buyer_email': 'exports@craftsofindia.com',
        'buyer_phone': '+919876543210',
        'buyer_type': 'wholesale_b2b',
        'quantity': 50,
        'target_price': '3800.00',
        'message': 'Looking for wholesale export order for London exhibition.',
        'status': 'pending',
        'created_at': '2026-09-09T18:00:00Z',
        'updated_at': '2026-09-09T18:00:00Z',
      },
      {
        'id': 102,
        'product_id': 2,
        'product_name': 'Terracotta Water Pot',
        'product_price': '450.00',
        'product_image_url': null,
        'buyer_name': 'Aarav Sharma',
        'buyer_email': 'aarav@gmail.com',
        'buyer_phone': '+919123456780',
        'buyer_type': 'retail',
        'quantity': 2,
        'target_price': '450.00',
        'message': 'Interested in buying 2 pieces for home decor.',
        'status': 'contacted',
        'created_at': '2026-09-09T17:30:00Z',
        'updated_at': '2026-09-09T17:45:00Z',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> updateInquiryStatus(int inquiryId, String newStatus) async {
    return {
      'id': inquiryId,
      'status': newStatus,
    };
  }
}

void main() {
  group('InquiriesScreen Widget Tests', () {
    testWidgets('Renders inquiry list and filters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InquiriesScreen(
            productService: MockInquiryProductService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Buyer Leads & Inquiries'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Contacted'), findsOneWidget);

      // Verify inquiry items
      expect(find.text('Crafts of India Exports'), findsOneWidget);
      expect(find.text('Handwoven Sambalpuri Saree'), findsOneWidget);
      expect(find.text('Quantity: 50 units'), findsOneWidget);
      expect(find.text('Mark Contacted'), findsOneWidget);

      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Terracotta Water Pot'), findsOneWidget);
      expect(find.text('Accept Deal'), findsOneWidget);
    });

    testWidgets('Tapping Mark Contacted updates status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InquiriesScreen(
            productService: MockInquiryProductService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark Contacted'));
      await tester.pumpAndSettle();

      expect(find.text('Lead status updated to CONTACTED'), findsOneWidget);
    });

    testWidgets('Renders empty state when no leads exist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InquiriesScreen(
            productService: MockInquiryProductService(returnEmpty: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No buyer inquiries yet'), findsOneWidget);
    });
  });
}
