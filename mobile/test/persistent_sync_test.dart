import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/services/product_service.dart';
import 'package:artisan_mobile/services/sync_service.dart';

void main() {
  group('Persistent Sync Queue Tests', () {
    late Directory tempDir;
    late File queueFile;
    late SyncQueueStorage persistentStorage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sync_test_');
      queueFile = File('${tempDir.path}/sync_queue.json');
      persistentStorage = FileJsonSyncQueueStorage(customFile: queueFile);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Queue items survive app re-instantiation via persistent storage', () async {
      // 1. Initialize first SyncService instance with persistent storage
      final syncService1 = SyncService(storage: persistentStorage);
      await syncService1.loadQueue();

      expect(syncService1.pendingCount, 0);

      // Enqueue 2 operations
      syncService1.queueProductCreate({
        'name': 'Blue Pottery Plate',
        'category': 'Pottery',
        'price': '450.00',
      });
      syncService1.queueProductUpdate(42, {'price': '500.00'});
      await syncService1.persistQueue();

      expect(syncService1.pendingCount, 2);

      // Verify file exists on disk and contains valid JSON
      expect(queueFile.existsSync(), isTrue);
      final content = jsonDecode(queueFile.readAsStringSync());
      expect(content, isList);
      expect(content.length, 2);

      // 2. Simulate app kill & restart by creating a new SyncService with the same storage
      final syncService2 = SyncService(storage: persistentStorage);
      await syncService2.loadQueue();

      expect(syncService2.pendingCount, 2);
      expect(syncService2.pendingQueue[0].actionType, 'create_product');
      expect(syncService2.pendingQueue[0].payload['name'], 'Blue Pottery Plate');
      expect(syncService2.pendingQueue[1].actionType, 'update_product');
      expect(syncService2.pendingQueue[1].payload['id'], 42);
    });

    test('Flushing queue successfully removes items from disk persistence', () async {
      final syncService = SyncService(storage: persistentStorage);
      await syncService.loadQueue();

      syncService.queueProductCreate({
        'name': 'Dhokra Brass Figurine',
        'category': 'Metal Craft',
        'price': '1200.00',
      });

      expect(syncService.pendingCount, 1);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'total_actions': 1,
            'applied_count': 1,
            'already_processed_count': 0,
            'failed_count': 0,
            'results': [
              {
                'client_action_id': 'any',
                'status': 'applied',
                'server_id': 202,
                'message': 'Saved',
              }
            ],
            'server_time': '2026-09-09T22:00:00Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final productService = ProductService(apiClient: ApiClient(client: mockClient));
      final result = await syncService.flushQueue(productService, 1);

      expect(result['success'], isTrue);
      expect(syncService.pendingCount, 0);

      // Verify disk storage is also updated to empty
      final restartedSync = SyncService(storage: persistentStorage);
      await restartedSync.loadQueue();
      expect(restartedSync.pendingCount, 0);
    });

    test('ClearQueue removes queue from memory and disk', () async {
      final syncService = SyncService(storage: persistentStorage);
      syncService.queueProductCreate({'name': 'Test Item'});
      expect(syncService.pendingCount, 1);

      syncService.clearQueue();
      expect(syncService.pendingCount, 0);

      final reloaded = SyncService(storage: persistentStorage);
      await reloaded.loadQueue();
      expect(reloaded.pendingCount, 0);
    });
  });
}
