import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_mobile/models/marketplace_product.dart';
import 'package:artisan_mobile/screens/marketplace/marketplace_product_detail_screen.dart';
import 'package:artisan_mobile/screens/marketplace/marketplace_screen.dart';
import 'package:artisan_mobile/services/product_service.dart';

class MockMarketplaceProductService extends ProductService {
  final List<Map<String, dynamic>> mockFeed = [
    {
      'id': 101,
      'artisan_id': 1,
      'artisan_name': 'Sunita Devi',
      'artisan_location': 'Madhubani, Bihar',
      'craft_type': 'Tribal Painting',
      'artisan_state': 'Bihar',
      'artisan_district': 'Madhubani',
      'artisan_bio': 'Master Madhubani artist with 20 years experience in natural dyes.',
      'name': 'Tree of Life Madhubani Painting',
      'category': 'Tribal Painting',
      'description': 'Handcrafted traditional Mithila artwork made with natural plant dyes.',
      'material': 'Handmade Paper & Natural Dyes',
      'price': '1850.00',
      'image_urls': ['https://example.com/tree.jpg'],
      'created_at': '2026-09-09T10:00:00Z',
    },
    {
      'id': 102,
      'artisan_id': 2,
      'artisan_name': 'Gopal Das',
      'artisan_location': 'Puri, Odisha',
      'craft_type': 'Pottery & Ceramics',
      'artisan_state': 'Odisha',
      'artisan_district': 'Puri',
      'name': 'Terracotta Temple Water Vessel',
      'category': 'Pottery & Ceramics',
      'description': 'Earthen clay water pot with cooling porous properties.',
      'material': 'Terracotta Clay',
      'price': '450.00',
      'image_urls': [],
      'created_at': '2026-09-09T11:00:00Z',
    },
  ];

  Map<String, dynamic>? lastSubmittedInquiry;
  int? lastInquiryProductId;

  @override
  Future<List<Map<String, dynamic>>> getMarketplaceProducts({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    int limit = 50,
    int offset = 0,
  }) async {
    return mockFeed.where((p) {
      if (query != null && query.isNotEmpty) {
        final matchesName = p['name'].toString().toLowerCase().contains(query.toLowerCase());
        final matchesCat = p['category'].toString().toLowerCase().contains(query.toLowerCase());
        if (!matchesName && !matchesCat) return false;
      }
      if (category != null && category != 'All') {
        if (!p['category'].toString().toLowerCase().contains(category.toLowerCase())) {
          return false;
        }
      }
      if (minPrice != null) {
        final price = double.tryParse(p['price'].toString()) ?? 0;
        if (price < minPrice) return false;
      }
      if (maxPrice != null) {
        final price = double.tryParse(p['price'].toString()) ?? 0;
        if (price > maxPrice) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> submitProductInquiry(
    int productId,
    Map<String, dynamic> inquiryData,
  ) async {
    lastInquiryProductId = productId;
    lastSubmittedInquiry = inquiryData;
    return {
      'id': 701,
      'product_id': productId,
      'buyer_name': inquiryData['buyer_name'],
      'status': 'pending',
      'created_at': '2026-09-10T00:00:00Z',
    };
  }
}

void main() {
  group('Buyer Marketplace Experience Widget Tests', () {
    late MockMarketplaceProductService mockService;

    setUp(() {
      mockService = MockMarketplaceProductService();
    });

    testWidgets('Renders MarketplaceScreen with search, categories, and products', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MarketplaceScreen(productService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buyer Discovery Marketplace'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Handloom & Textiles'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Pottery & Ceramics'), findsOneWidget);

      // Verify product cards appear
      expect(find.text('Tree of Life Madhubani Painting'), findsOneWidget);
      expect(find.text('By Sunita Devi'), findsOneWidget);
      expect(find.text('₹1850.00'), findsOneWidget);

      expect(find.text('Terracotta Temple Water Vessel'), findsOneWidget);
      expect(find.text('By Gopal Das'), findsOneWidget);
      expect(find.text('₹450.00'), findsOneWidget);
    });

    testWidgets('Search filters products in marketplace feed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MarketplaceScreen(productService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField), 'Terracotta');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Only Terracotta Vessel should be visible
      expect(find.text('Terracotta Temple Water Vessel'), findsOneWidget);
      expect(find.text('Tree of Life Madhubani Painting'), findsNothing);
    });

    testWidgets('Category chips filter marketplace feed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MarketplaceScreen(productService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pottery & Ceramics chip specifically
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pottery & Ceramics'));
      await tester.pumpAndSettle();

      expect(find.text('Terracotta Temple Water Vessel'), findsOneWidget);
      expect(find.text('Tree of Life Madhubani Painting'), findsNothing);
    });

    testWidgets('MarketplaceProductDetailScreen renders safe public artisan info and submits inquiry', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleProduct = MarketplaceProduct.fromJson(mockService.mockFeed[0]);

      await tester.pumpWidget(
        MaterialApp(
          home: MarketplaceProductDetailScreen(
            product: sampleProduct,
            productService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Product and safe artisan info
      expect(find.text('Tree of Life Madhubani Painting'), findsNWidgets(2)); // AppBar + body
      expect(find.text('Verified Handmade'), findsOneWidget);
      expect(find.text('Sunita Devi'), findsOneWidget);
      expect(find.text('Origin: Madhubani, Bihar'), findsOneWidget);

      // Open Inquiry Bottom Sheet
      await tester.tap(find.text('Send Inquiry'));
      await tester.pumpAndSettle();

      expect(find.text('💼 Send Business Inquiry'), findsOneWidget);

      // Fill in inquiry fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Your Name or Business *'), 'FabIndia Buyer Desk');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address *'), 'procurement@fabindia.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Phone *'), '+919876543210');

      // Submit inquiry
      await tester.tap(find.text('Submit Business Inquiry'));
      await tester.pumpAndSettle();

      // Verify Service called
      expect(mockService.lastInquiryProductId, equals(101));
      expect(mockService.lastSubmittedInquiry?['buyer_name'], equals('FabIndia Buyer Desk'));
      expect(mockService.lastSubmittedInquiry?['buyer_email'], equals('procurement@fabindia.com'));
    });
  });
}
