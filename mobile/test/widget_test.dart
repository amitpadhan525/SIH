import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/screens/home/home_screen.dart';
import 'package:artisan_mobile/screens/products/products_screen.dart';
import 'package:artisan_mobile/screens/product_detail/product_detail_screen.dart';
import 'package:artisan_mobile/services/product_service.dart';

void main() {
  testWidgets('HomeScreen renders greeting and primary action buttons', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path == '/health/db') {
        return http.Response(jsonEncode({'database': 'connected'}), 200);
      }
      return http.Response(jsonEncode([]), 200);
    });

    final service = ProductService(apiClient: ApiClient(client: mockClient));

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(productService: service),
      ),
    );

    // Initial pump
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Artisan Studio'), findsOneWidget);
    expect(find.text('Namaste 🙏'), findsOneWidget);
    expect(find.text('Add New Product'), findsOneWidget);
    expect(find.text('View All Products'), findsOneWidget);
  });

  testWidgets('ProductsScreen displays empty state when no products exist', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(jsonEncode([]), 200);
    });

    final service = ProductService(apiClient: ApiClient(client: mockClient));

    await tester.pumpWidget(
      MaterialApp(
        home: ProductsScreen(productService: service),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No products yet'), findsOneWidget);
    expect(find.text('Add Your First Product'), findsOneWidget);
  });

  testWidgets('ProductsScreen displays product card when products exist', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode([
          {
            'id': 1,
            'artisan_id': 1,
            'name': 'Terracotta Mug',
            'category': 'Pottery',
            'price': '250.00',
            'status': 'published',
          }
        ]),
        200,
      );
    });

    final service = ProductService(apiClient: ApiClient(client: mockClient));

    await tester.pumpWidget(
      MaterialApp(
        home: ProductsScreen(productService: service),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Terracotta Mug'), findsOneWidget);
    expect(find.text('₹250.00'), findsOneWidget);
    expect(find.text('PUBLISHED'), findsOneWidget);
  });

  testWidgets('ProductDetailScreen displays details and ONDC / GeM export buttons', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path == '/products/1') {
        return http.Response(
          jsonEncode({
            'id': 1,
            'artisan_id': 1,
            'name': 'Silk Dupatta',
            'category': 'Textiles',
            'material': 'Pure Silk',
            'price': '1200.00',
            'description': 'Handwoven silk dupatta with border embroidery.',
            'status': 'published',
            'images': [],
          }),
          200,
        );
      }
      if (request.url.path == '/products/1/images') {
        return http.Response(jsonEncode([]), 200);
      }
      return http.Response(jsonEncode({}), 200);
    });

    final service = ProductService(apiClient: ApiClient(client: mockClient));

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(
          productId: 1,
          productService: service,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Silk Dupatta'), findsOneWidget);
    expect(find.text('Pure Silk'), findsOneWidget);
    expect(find.text('ONDC JSON'), findsOneWidget);
    expect(find.text('GeM Govt'), findsOneWidget);
  });
}
