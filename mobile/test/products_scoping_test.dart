import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/screens/products/products_screen.dart';
import 'package:artisan_mobile/services/auth_service.dart';
import 'package:artisan_mobile/services/product_service.dart';

void main() {
  group('ProductsScreen Artisan Scoping Tests', () {
    testWidgets('ProductsScreen passes authenticated artisanId and shows empty state for new artisan', (WidgetTester tester) async {
      int? requestedArtisanId;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/products') {
          requestedArtisanId = int.tryParse(request.url.queryParameters['artisan_id'] ?? '');
          // New artisan has 0 products
          return http.Response(jsonEncode([]), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response(jsonEncode({}), 200);
      });

      final authService = AuthService(apiClient: ApiClient(client: mockClient));
      final productService = ProductService(apiClient: authService.apiClient);

      // Authenticate as a brand new artisan (id: 42)
      authService.setSession(
        token: 'test_token',
        user: {
          'user_id': 42,
          'artisan_id': 42,
          'full_name': 'New Artisan',
          'is_profile_complete': true,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProductsScreen(
            productService: productService,
            authService: authService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the request specifically passed artisan_id=42
      expect(requestedArtisanId, equals(42));

      // Verify clean empty state is shown, not other artisans' items
      expect(find.text('No products yet'), findsOneWidget);
      expect(find.text('Add Your First Product'), findsOneWidget);
    });
  });
}
