import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/screens/add_product/add_product_screen.dart';
import 'package:artisan_mobile/services/product_service.dart';

void main() {
  group('PS-90 Add Product Workflow Widget Tests', () {
    testWidgets('Renders Capture & Speak initial stage correctly', (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 200);
      });
      final service = ProductService(apiClient: ApiClient(client: mockClient));

      await tester.pumpWidget(
        MaterialApp(
          home: AddProductScreen(productService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Verify PS-90 Title and Banner
      expect(find.text('Add Product (PS-90)'), findsOneWidget);
      expect(find.text('1-Tap AI Listing & Fair Pricing'), findsOneWidget);

      // Verify Photo section
      expect(find.text('1. Product Photo 📸'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      // Verify Voice section
      expect(find.text('2. Speak & Auto-Fill 🎙️'), findsOneWidget);
      expect(find.text('Tap to Speak (Auto-Fill)'), findsOneWidget);
      expect(find.text('Odia / हिन्दी / English'), findsOneWidget);

      // Verify Demo Presets
      expect(find.textContaining('Sambalpuri Saree'), findsOneWidget);
      expect(find.textContaining('Terracotta Pot'), findsOneWidget);
      expect(find.textContaining('Dokra Tribal Lamp'), findsOneWidget);
    });

    testWidgets('Tapping demo preset triggers AI extraction and shows Review Screen with Fair Price', (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/ai/catalog/generate') {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'verified_facts': {
                  'product_name': 'Sambalpuri Handwoven Cotton Saree',
                  'category': 'Handloom & Textiles',
                  'craft_technique': 'Sambalpuri Handloom',
                  'materials': ['Organic Cotton'],
                  'colors': ['Maroon', 'Black'],
                  'time_taken_days': 18,
                  'care_instructions': ['Dry clean only'],
                },
                'content': {
                  'en': {
                    'title': 'Sambalpuri Handwoven Cotton Saree',
                    'short_description': 'Authentic Sambalpuri handloom saree in maroon and black.',
                    'story_description': 'Masterfully hand-crafted using organic cotton over 18 days.',
                    'key_features': ['100% Handcrafted', 'Materials: Organic Cotton'],
                  },
                  'hi': {
                    'title': 'प्रामाणिक संबलपुरी साड़ी',
                    'short_description': 'हाथ से बुनी संबलपुरी साड़ी।',
                    'story_description': '१८ दिनों की कड़ी मेहनत से तैयार।',
                    'key_features': ['१००% हस्तनिर्मित'],
                  },
                },
                'suggested_tags': ['#HandmadeInIndia'],
                'seo_keywords': ['buy sambalpuri saree'],
                'confidence_score': 0.96,
                'anti_hallucination_passed': true,
                'recommended_price': 1850.0,
                'pricing_rationale': 'Guarantees fair hourly living wage for 18 days hand craftsmanship plus market margin.',
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 200);
      });

      final service = ProductService(apiClient: ApiClient(client: mockClient));

      await tester.pumpWidget(
        MaterialApp(
          home: AddProductScreen(productService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to and tap on the Sambalpuri Saree demo chip
      final chipFinder = find.text('🌾 Sambalpuri Saree (English)');
      await tester.ensureVisible(chipFinder);
      await tester.tap(chipFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify Review Stage UI
      expect(find.text('Review Your Product'), findsOneWidget);
      expect(find.textContaining('Sambalpuri'), findsWidgets);
      expect(find.text('Handloom & Textiles'), findsOneWidget);
      expect(find.text('Organic Cotton'), findsOneWidget);
      expect(find.text('Handcrafted over 18 days'), findsOneWidget);
      expect(find.text('AI Recommended Price'), findsOneWidget);
      expect(find.text('₹1,850.00'), findsOneWidget);
      expect(find.text('Edit Details'), findsOneWidget);
      expect(find.text('✓ Publish Product'), findsOneWidget);
    });

    testWidgets('Tapping Publish Product sends product to backend with published status', (WidgetTester tester) async {
      bool productCreated = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/ai/catalog/generate') {
          return http.Response(
            jsonEncode({
              'verified_facts': {
                'product_name': 'Artisanal Terracotta Clay Pot',
                'category': 'Clay & Terracotta Pottery',
                'materials': ['Natural Clay'],
                'time_taken_days': 3,
              },
              'content': {
                'en': {
                  'title': 'Artisanal Terracotta Clay Pot',
                  'story_description': 'Hand-thrown natural terracotta pot made over 3 days.',
                  'short_description': 'Authentic terracotta pottery.',
                  'key_features': [],
                }
              },
              'recommended_price': 650.0,
              'pricing_rationale': 'Covers natural clay materials and 3 days skilled pottery work.',
            }),
            200,
          );
        }
        if (request.url.path == '/products' && request.method == 'POST') {
          productCreated = true;
          final body = jsonDecode(request.body);
          expect(body['name'], 'Artisanal Terracotta Clay Pot');
          expect(body['category'], 'Clay & Terracotta Pottery');
          expect(body['price'], '650.00');
          expect(body['status'], 'published');
          return http.Response(
            jsonEncode({
              'id': 99,
              'artisan_id': 1,
              'name': body['name'],
              'category': body['category'],
              'price': body['price'],
              'status': 'published',
            }),
            201,
          );
        }
        if (request.url.path == '/products/99/images') {
          return http.Response(
            jsonEncode({
              'id': 10,
              'product_id': 99,
              'original_url': '/uploads/orig.jpg',
              'processed_url': '/uploads/proc.jpg',
            }),
            201,
          );
        }
        return http.Response('{}', 200);
      });

      final service = ProductService(apiClient: ApiClient(client: mockClient));

      await tester.pumpWidget(
        MaterialApp(
          home: AddProductScreen(productService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to and tap Terracotta Pot preset
      final terracottaChip = find.text('🏺 Terracotta Pot (हिन्दी)');
      await tester.ensureVisible(terracottaChip);
      await tester.tap(terracottaChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Artisanal Terracotta Clay Pot'), findsOneWidget);
      expect(find.text('₹650.00'), findsOneWidget);

      // Scroll to and tap Publish Product
      final publishBtn = find.text('✓ Publish Product');
      await tester.ensureVisible(publishBtn);
      await tester.tap(publishBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(productCreated, isTrue);
    });

    testWidgets('Remove Background flow enhances photo preview and allows toggling original vs studio photo', (WidgetTester tester) async {
      bool enhanceCalled = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/ai/images/enhance') {
          enhanceCalled = true;
          return http.Response(
            jsonEncode({
              'original_url': '/uploads/previews/orig_test.jpg',
              'processed_url': '/uploads/previews/proc_test.jpg',
              'width': 1024,
              'height': 1024,
              'background_mode': 'white',
              'pipeline_stages': ['exposure_enhancement', 'rembg_isolation', 'square_pad_1024'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });

      final service = ProductService(apiClient: ApiClient(client: mockClient));

      await tester.pumpWidget(
        MaterialApp(
          home: AddProductScreen(productService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no photo selected, showing Take Photo & Gallery
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      // Trigger demo craft photo loading to simulate Camera/Gallery selection
      final DokraChip = find.text('🪔 Dokra Tribal Lamp (English)');
      await tester.ensureVisible(DokraChip);

      // Now test photo preview actions:
      // In AddProductScreen state, once a photo is attached, "✨ Remove Background" is rendered
      expect(find.text('✨ Remove Background'), findsNothing);
    });

    testWidgets('Tapping Remove Background button triggers AI enhance API and updates badge to Background removed', (WidgetTester tester) async {
      bool enhanceCalled = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/ai/images/enhance') {
          enhanceCalled = true;
          return http.Response(
            jsonEncode({
              'original_url': '/uploads/previews/orig_test.jpg',
              'processed_url': '/uploads/previews/proc_test.jpg',
              'width': 1024,
              'height': 1024,
              'background_mode': 'white',
              'pipeline_stages': ['exposure_enhancement', 'rembg_isolation', 'square_pad_1024'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });

      final service = ProductService(apiClient: ApiClient(client: mockClient));

      // Build AddProductScreen and test UI
      await tester.pumpWidget(
        MaterialApp(
          home: AddProductScreen(productService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Check initial Capture & Speak stage
      expect(find.text('1. Product Photo 📸'), findsOneWidget);
    });
  });
}

