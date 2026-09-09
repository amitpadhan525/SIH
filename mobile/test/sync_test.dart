import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/services/product_service.dart';
import 'package:artisan_mobile/services/sync_service.dart';

void main() {
  group('Mobile Sync Service Tests', () {
    late SyncService syncService;

    setUp(() {
      syncService = SyncService();
      syncService.clearQueue();
    });

    test('Queues product create and update actions offline', () {
      expect(syncService.pendingCount, 0);
      expect(syncService.hasPendingActions, isFalse);

      syncService.queueProductCreate({
        'name': 'Terracotta Vase',
        'category': 'Pottery',
        'price': '850.00',
      });

      expect(syncService.pendingCount, 1);
      expect(syncService.hasPendingActions, isTrue);
      expect(syncService.pendingQueue.first.actionType, equals('create_product'));
      expect(syncService.pendingQueue.first.clientActionId, isNotEmpty);

      syncService.queueProductUpdate(12, {'price': '950.00'});
      expect(syncService.pendingCount, 2);
    });

    test('flushQueue flushes batch to backend and clears queue on success', () async {
      syncService.queueProductCreate({
        'name': 'Terracotta Vase',
        'category': 'Pottery',
        'price': '850.00',
      });

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/sync/batch');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['artisan_id'], 1);
        expect(body['actions'], isList);
        expect(body['actions'].length, 1);

        return http.Response(
          jsonEncode({
            'success': true,
            'total_actions': 1,
            'applied_count': 1,
            'already_processed_count': 0,
            'failed_count': 0,
            'results': [
              {
                'client_action_id': body['actions'][0]['client_action_id'],
                'status': 'applied',
                'server_id': 101,
                'message': 'Product successfully synced',
              }
            ],
            'server_time': '2026-09-09T20:30:00Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final productService = ProductService(apiClient: ApiClient(client: mockClient));
      final res = await syncService.flushQueue(productService, 1);

      expect(res['success'], isTrue);
      expect(res['applied_count'], equals(1));
      expect(syncService.pendingCount, 0);
    });

    test('getSyncDelta fetches delta changes correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/sync/delta');
        expect(request.url.queryParameters['artisan_id'], '1');

        return http.Response(
          jsonEncode({
            'server_time': '2026-09-09T20:30:00Z',
            'products': [
              {'id': 101, 'name': 'Terracotta Vase', 'price': '850.00', 'status': 'draft'}
            ],
            'inquiries': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final productService = ProductService(apiClient: ApiClient(client: mockClient));
      final delta = await productService.getSyncDelta(1);

      expect(delta['products'], isList);
      expect(delta['products'].length, equals(1));
      expect(delta['products'][0]['name'], equals('Terracotta Vase'));
    });
  });
}
