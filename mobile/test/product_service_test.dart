import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/models/product.dart';
import 'package:artisan_mobile/services/product_service.dart';

void main() {
  group('ProductService CRUD Operations', () {
    test('getProducts parses list of products from backend correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/products');
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'artisan_id': 1,
              'name': 'Cotton Bag',
              'category': 'Handicraft',
              'price': '650.00',
              'status': 'draft',
            },
            {
              'id': 2,
              'artisan_id': 1,
              'name': 'Clay Pot',
              'category': 'Pottery',
              'price': '350.00',
              'status': 'published',
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final service = ProductService(apiClient: apiClient);

      final products = await service.getProducts();

      expect(products.length, 2);
      expect(products[0].name, 'Cotton Bag');
      expect(products[0].price, '650.00');
      expect(products[1].name, 'Clay Pot');
      expect(products[1].status, 'published');
    });

    test('createProduct posts valid JSON and returns created Product', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/products');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['name'], 'Handcrafted Wood Vase');
        expect(body['price'], '850.00');

        return http.Response(
          jsonEncode({
            'id': 15,
            'artisan_id': 1,
            'name': 'Handcrafted Wood Vase',
            'category': 'Woodwork',
            'price': '850.00',
            'status': 'draft',
            'created_at': '2026-09-09T18:00:00Z',
            'updated_at': '2026-09-09T18:00:00Z',
            'images': [],
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final service = ProductService(apiClient: apiClient);

      const toCreate = Product(
        artisanId: 1,
        name: 'Handcrafted Wood Vase',
        category: 'Woodwork',
        price: '850.00',
      );

      final created = await service.createProduct(toCreate);

      expect(created.id, 15);
      expect(created.name, 'Handcrafted Wood Vase');
      expect(created.price, '850.00');
    });

    test('getProduct returns single product by ID', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/products/42');
        return http.Response(
          jsonEncode({
            'id': 42,
            'artisan_id': 1,
            'name': 'Silk Saree',
            'category': 'Textiles',
            'price': '4500.00',
            'status': 'published',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final service = ProductService(apiClient: apiClient);

      final product = await service.getProduct(42);

      expect(product.id, 42);
      expect(product.name, 'Silk Saree');
      expect(product.price, '4500.00');
    });

    test('updateProduct sends PUT and receives updated product', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/products/42');
        expect(request.method, 'PUT');
        final body = jsonDecode(request.body);
        expect(body.containsKey('artisan_id'), isFalse);
        expect(body['name'], 'Silk Saree (Special Edition)');

        return http.Response(
          jsonEncode({
            'id': 42,
            'artisan_id': 1,
            'name': 'Silk Saree (Special Edition)',
            'category': 'Textiles',
            'price': '4800.00',
            'status': 'published',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final service = ProductService(apiClient: apiClient);

      const toUpdate = Product(
        id: 42,
        artisanId: 1,
        name: 'Silk Saree (Special Edition)',
        category: 'Textiles',
        price: '4800.00',
        status: 'published',
      );

      final updated = await service.updateProduct(42, toUpdate);

      expect(updated.name, 'Silk Saree (Special Edition)');
      expect(updated.price, '4800.00');
    });

    test('deleteProduct sends DELETE request', () async {
      bool deleteCalled = false;
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/products/42');
        expect(request.method, 'DELETE');
        deleteCalled = true;
        return http.Response('', 204);
      });

      final apiClient = ApiClient(client: mockClient);
      final service = ProductService(apiClient: apiClient);

      await service.deleteProduct(42);
      expect(deleteCalled, isTrue);
    });

    test('throws friendly ApiException when backend returns 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Product not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final service = ProductService(apiClient: apiClient);

      expect(
        () => service.getProduct(9999),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Product not found',
        )),
      );
    });
  });
}
