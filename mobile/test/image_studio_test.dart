import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/models/product_image.dart';
import 'package:artisan_mobile/screens/image_studio/image_studio_screen.dart';
import 'package:artisan_mobile/services/product_service.dart';

void main() {
  group('ProductImage Model Tests', () {
    test('ProductImage.fromJson parses valid payload', () {
      final json = {
        'id': 10,
        'product_id': 5,
        'original_url': '/uploads/originals/test_orig.jpg',
        'processed_url': '/uploads/processed/test_proc.jpg',
        'created_at': '2026-09-09T18:00:00Z',
      };

      final image = ProductImage.fromJson(json);
      expect(image.id, 10);
      expect(image.productId, 5);
      expect(image.originalUrl, '/uploads/originals/test_orig.jpg');
      expect(image.processedUrl, '/uploads/processed/test_proc.jpg');
      expect(image.createdAt, isNotNull);
    });

    test('ProductImage.toJson serializes correctly', () {
      const image = ProductImage(
        id: 1,
        productId: 2,
        originalUrl: '/uploads/originals/1.jpg',
        processedUrl: '/uploads/processed/1.jpg',
      );

      final json = image.toJson();
      expect(json['id'], 1);
      expect(json['product_id'], 2);
      expect(json['original_url'], '/uploads/originals/1.jpg');
    });
  });

  group('ImageStudioScreen Widget Tests', () {
    testWidgets('Photo Studio renders header, camera card, and gallery card in idle state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ImageStudioScreen(),
        ),
      );

      expect(find.text('AI Photo Studio'), findsOneWidget);
      expect(find.text('AI Product Enhancer'), findsOneWidget);
      expect(find.text('Take Photo with Camera'), findsOneWidget);
      expect(find.text('Upload from Photo Gallery'), findsOneWidget);
      expect(find.text('Terracotta Vase'), findsOneWidget);
      expect(find.text('Silk Saree'), findsOneWidget);
    });

    testWidgets('Selecting photo shows preview and triggers processing on enhance tap',
        (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/ai/images/enhance') {
          return http.Response(
            jsonEncode({
              'original_url': '/uploads/previews/orig_test.jpg',
              'processed_url': '/uploads/previews/proc_test.jpg',
              'width': 1024,
              'height': 1024,
              'background_mode': 'white',
              'pipeline_stages': ['autocontrast', 'ecommerce_1024_square_canvas'],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = ProductService(apiClient: ApiClient(client: mockClient));

      await tester.pumpWidget(
        MaterialApp(
          home: ImageStudioScreen(productService: service),
        ),
      );

      // Tap sample craft chip to select photo
      await tester.tap(find.text('Terracotta Vase'));
      await tester.pumpAndSettle();

      // Verify preview state
      expect(find.text('Studio Background Style:'), findsOneWidget);
      expect(find.text('✨ Enhance Photo with AI'), findsOneWidget);

      // Scroll to enhance button and tap
      await tester.ensureVisible(find.text('✨ Enhance Photo with AI'));
      await tester.tap(find.text('✨ Enhance Photo with AI'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Confirm processed state rendered
      expect(find.text('✨ AI Studio (After)'), findsOneWidget);
      expect(find.text('Original Photo (Before)'), findsOneWidget);
      expect(find.text('Apply & Attach to Product'), findsOneWidget);
    });

    testWidgets('Displays accessible error view on server failure and supports retry',
        (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Photo is too large. Maximum size is 10 MB.'}),
          400,
        );
      });

      final service = ProductService(apiClient: ApiClient(client: mockClient));

      await tester.pumpWidget(
        MaterialApp(
          home: ImageStudioScreen(productService: service),
        ),
      );

      await tester.tap(find.text('Terracotta Vase'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('✨ Enhance Photo with AI'));
      await tester.tap(find.text('✨ Enhance Photo with AI'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Photo is too large. Maximum size is 10 MB.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('Selecting Transparent PNG background mode passes transparent parameter and returns result on Apply',
        (WidgetTester tester) async {
      String? capturedBgMode;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/ai/images/enhance') {
          capturedBgMode = request.url.queryParameters['background_mode'];
          return http.Response(
            jsonEncode({
              'original_url': '/uploads/previews/orig_test.jpg',
              'processed_url': '/uploads/previews/proc_test.png',
              'width': 1024,
              'height': 1024,
              'background_mode': 'transparent',
              'pipeline_stages': ['rembg_u2netp_cutout', 'ecommerce_1024_square_canvas'],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = ProductService(apiClient: ApiClient(client: mockClient));

      Map<String, dynamic>? appliedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  final res = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => ImageStudioScreen(productService: service),
                    ),
                  );
                  appliedResult = res;
                },
                child: const Text('Launch Studio'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch Studio'));
      await tester.pumpAndSettle();

      // Tap sample craft
      await tester.tap(find.text('Terracotta Vase'));
      await tester.pumpAndSettle();

      // Tap Transparent PNG option
      expect(find.text('Transparent PNG'), findsOneWidget);
      await tester.tap(find.text('Transparent PNG'));
      await tester.pumpAndSettle();

      // Tap Enhance
      await tester.ensureVisible(find.text('✨ Enhance Photo with AI'));
      await tester.tap(find.text('✨ Enhance Photo with AI'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(capturedBgMode, 'transparent');
      expect(find.text('✨ AI Studio (After)'), findsOneWidget);

      // Tap Apply
      await tester.tap(find.text('Apply & Attach to Product'));
      await tester.pumpAndSettle();

      expect(appliedResult, isNotNull);
      expect(appliedResult!['background_mode'], 'transparent');
      expect(appliedResult!['processed_url'], '/uploads/previews/proc_test.png');
    });
  });
}

