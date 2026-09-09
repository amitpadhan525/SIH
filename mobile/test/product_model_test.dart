import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_mobile/models/product.dart';

void main() {
  group('Product Model Serialization & Precision', () {
    test('fromJson correctly parses complete product payload with Decimal string price', () {
      final json = {
        'id': 42,
        'artisan_id': 3,
        'name': 'Terracotta Water Pitcher',
        'category': 'Pottery',
        'description': 'Handcrafted clay cooling vessel',
        'material': 'Terracotta Clay',
        'price': '450.75',
        'status': 'published',
        'created_at': '2026-09-09T12:00:00Z',
        'updated_at': '2026-09-09T12:30:00Z',
        'images': [
          {
            'id': 1,
            'product_id': 42,
            'original_url': 'https://example.com/pitcher.jpg',
            'processed_url': 'https://example.com/clean_pitcher.png',
            'created_at': '2026-09-09T12:05:00Z',
          }
        ],
      };

      final product = Product.fromJson(json);

      expect(product.id, 42);
      expect(product.artisanId, 3);
      expect(product.name, 'Terracotta Water Pitcher');
      expect(product.category, 'Pottery');
      expect(product.description, 'Handcrafted clay cooling vessel');
      expect(product.material, 'Terracotta Clay');
      expect(product.price, '450.75'); // Exact monetary string without IEEE float loss
      expect(product.status, 'published');
      expect(product.createdAt, isNotNull);
      expect(product.updatedAt, isNotNull);
      expect(product.imageUrls.length, 1);
      expect(product.imageUrls.first, 'https://example.com/pitcher.jpg');
    });

    test('fromJson safely handles numeric price and nullable fields', () {
      final json = {
        'id': 10,
        'artisan_id': 1,
        'name': 'Minimal Bag',
        'category': 'Handicraft',
        'price': 650.00,
      };

      final product = Product.fromJson(json);

      expect(product.id, 10);
      expect(product.name, 'Minimal Bag');
      expect(product.category, 'Handicraft');
      expect(product.price, '650.0');
      expect(product.description, isNull);
      expect(product.material, isNull);
      expect(product.status, 'draft');
      expect(product.imageUrls, isEmpty);
    });

    test('toCreateJson outputs expected ProductCreate payload', () {
      const product = Product(
        artisanId: 5,
        name: '  Handmade Scarf  ',
        category: 'Textiles',
        material: 'Silk',
        price: '1200.50',
        status: 'draft',
      );

      final json = product.toCreateJson();

      expect(json['artisan_id'], 5);
      expect(json['name'], 'Handmade Scarf');
      expect(json['category'], 'Textiles');
      expect(json['material'], 'Silk');
      expect(json['price'], '1200.50');
      expect(json['status'], 'draft');
    });

    test('toUpdateJson excludes immutable fields (id and artisan_id)', () {
      const product = Product(
        id: 99,
        artisanId: 10,
        name: 'Updated Scarf',
        category: 'Textiles',
        price: '1500.00',
        status: 'published',
      );

      final json = product.toUpdateJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('artisan_id'), isFalse);
      expect(json['name'], 'Updated Scarf');
      expect(json['category'], 'Textiles');
      expect(json['price'], '1500.00');
      expect(json['status'], 'published');
    });
  });
}
