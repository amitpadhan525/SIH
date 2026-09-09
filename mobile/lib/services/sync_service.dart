import 'dart:math';
import 'package:artisan_mobile/services/product_service.dart';

class SyncAction {
  final String clientActionId;
  final String actionType;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  SyncAction({
    String? clientActionId,
    required this.actionType,
    required this.payload,
    DateTime? timestamp,
  })  : clientActionId = clientActionId ?? _generateUuid(),
        timestamp = timestamp ?? DateTime.now();

  static String _generateUuid() {
    final random = Random();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Map<String, dynamic> toJson() => {
        'client_action_id': clientActionId,
        'action_type': actionType,
        'payload': payload,
        'client_timestamp': timestamp.toIso8601String(),
      };
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final List<SyncAction> _pendingQueue = [];
  bool _isSyncing = false;

  List<SyncAction> get pendingQueue => List.unmodifiable(_pendingQueue);
  int get pendingCount => _pendingQueue.length;
  bool get hasPendingActions => _pendingQueue.isNotEmpty;
  bool get isSyncing => _isSyncing;

  void queueAction(SyncAction action) {
    _pendingQueue.add(action);
  }

  void queueProductCreate(Map<String, dynamic> productData) {
    _pendingQueue.add(
      SyncAction(
        actionType: 'create_product',
        payload: productData,
      ),
    );
  }

  void queueProductUpdate(int productId, Map<String, dynamic> changes) {
    final payload = Map<String, dynamic>.from(changes);
    payload['id'] = productId;
    _pendingQueue.add(
      SyncAction(
        actionType: 'update_product',
        payload: payload,
      ),
    );
  }

  void queueInquiryUpdate(int inquiryId, String newStatus) {
    _pendingQueue.add(
      SyncAction(
        actionType: 'update_inquiry_status',
        payload: {
          'inquiry_id': inquiryId,
          'status': newStatus,
        },
      ),
    );
  }

  void clearQueue() {
    _pendingQueue.clear();
  }

  /// Flushes all queued actions to the backend sync batch endpoint
  Future<Map<String, dynamic>> flushQueue(ProductService productService, int artisanId) async {
    if (_pendingQueue.isEmpty) {
      return {'success': true, 'applied_count': 0, 'message': 'No pending actions to sync.'};
    }

    _isSyncing = true;
    try {
      final actionsPayload = _pendingQueue.map((a) => a.toJson()).toList();
      final res = await productService.syncBatch(artisanId, actionsPayload);

      // Remove successfully applied or already processed items
      if (res['success'] == true || (res['applied_count'] ?? 0) > 0) {
        _pendingQueue.clear();
      }

      return res;
    } finally {
      _isSyncing = false;
    }
  }
}
