import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:artisan_mobile/services/product_service.dart';

abstract class SyncQueueStorage {
  Future<void> saveQueue(List<Map<String, dynamic>> items);
  Future<List<Map<String, dynamic>>> loadQueue();
  Future<void> clear();
}

class FileJsonSyncQueueStorage implements SyncQueueStorage {
  final String _filename;
  File? _cachedFile;

  FileJsonSyncQueueStorage({String filename = 'artisan_sync_queue.json', File? customFile})
      : _filename = filename,
        _cachedFile = customFile;

  Future<File> _getFile() async {
    if (_cachedFile != null) return _cachedFile!;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _cachedFile = File('${dir.path}/$_filename');
      return _cachedFile!;
    } catch (_) {
      // Fallback for tests or unsupported directory environments
      _cachedFile = File('./$_filename');
      return _cachedFile!;
    }
  }

  @override
  Future<void> saveQueue(List<Map<String, dynamic>> items) async {
    try {
      final file = await _getFile();
      final jsonStr = jsonEncode(items);
      await file.writeAsString(jsonStr, flush: true);
    } catch (_) {
      // Ignore persistence errors silently in edge test environments
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadQueue() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> clear() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore
    }
  }
}

class InMemorySyncQueueStorage implements SyncQueueStorage {
  List<Map<String, dynamic>> _data = [];

  @override
  Future<void> saveQueue(List<Map<String, dynamic>> items) async {
    _data = List<Map<String, dynamic>>.from(items);
  }

  @override
  Future<List<Map<String, dynamic>>> loadQueue() async {
    return List<Map<String, dynamic>>.from(_data);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }
}

class SyncAction {
  final String clientActionId;
  final String actionType;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  int retryCount;
  String status; // 'pending', 'syncing', 'failed'
  String? lastError;

  SyncAction({
    String? clientActionId,
    required this.actionType,
    required this.payload,
    DateTime? timestamp,
    this.retryCount = 0,
    this.status = 'pending',
    this.lastError,
  })  : clientActionId = clientActionId ?? _generateUuid(),
        timestamp = timestamp ?? DateTime.now();

  static String _generateUuid() {
    final random = Random();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  factory SyncAction.fromJson(Map<String, dynamic> json) {
    return SyncAction(
      clientActionId: json['client_action_id'] as String?,
      actionType: json['action_type'] as String? ?? 'unknown',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      timestamp: json['client_timestamp'] != null
          ? DateTime.tryParse(json['client_timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      retryCount: json['retry_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      lastError: json['last_error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'client_action_id': clientActionId,
        'action_type': actionType,
        'payload': payload,
        'client_timestamp': timestamp.toIso8601String(),
        'retry_count': retryCount,
        'status': status,
        'last_error': lastError,
      };
}

class SyncService {
  static SyncService _instance = SyncService._internal();
  factory SyncService({SyncQueueStorage? storage}) {
    if (storage != null) {
      _instance = SyncService._internal(storage: storage);
    }
    return _instance;
  }

  SyncService._internal({SyncQueueStorage? storage})
      : _storage = storage ?? FileJsonSyncQueueStorage();

  final SyncQueueStorage _storage;
  final List<SyncAction> _pendingQueue = [];
  bool _isSyncing = false;
  bool _isLoaded = false;

  List<SyncAction> get pendingQueue => List.unmodifiable(_pendingQueue);
  int get pendingCount => _pendingQueue.length;
  bool get hasPendingActions => _pendingQueue.isNotEmpty;
  bool get isSyncing => _isSyncing;
  bool get isLoaded => _isLoaded;
  SyncQueueStorage get storage => _storage;

  Future<void> _persistQueue() async {
    final list = _pendingQueue.map((a) => a.toJson()).toList();
    await _storage.saveQueue(list);
  }

  /// Explicitly persist queue (useful after queueing operations)
  Future<void> persistQueue() => _persistQueue();

  /// Loads persisted offline actions from storage
  Future<void> loadQueue() async {
    final rawList = await _storage.loadQueue();
    _pendingQueue.clear();
    for (final raw in rawList) {
      _pendingQueue.add(SyncAction.fromJson(raw));
    }
    _isLoaded = true;
  }

  void queueAction(SyncAction action) {
    // Avoid duplicate enqueue if clientActionId is already present
    if (!_pendingQueue.any((a) => a.clientActionId == action.clientActionId)) {
      _pendingQueue.add(action);
      _persistQueue();
    }
  }

  void queueProductCreate(Map<String, dynamic> productData) {
    queueAction(
      SyncAction(
        actionType: 'create_product',
        payload: productData,
      ),
    );
  }

  void queueProductUpdate(int productId, Map<String, dynamic> changes) {
    final payload = Map<String, dynamic>.from(changes);
    payload['id'] = productId;
    queueAction(
      SyncAction(
        actionType: 'update_product',
        payload: payload,
      ),
    );
  }

  void queueInquiryUpdate(int inquiryId, String newStatus) {
    queueAction(
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
    _storage.clear();
  }

  /// Flushes all queued actions to the backend sync batch endpoint
  Future<Map<String, dynamic>> flushQueue(ProductService productService, int artisanId) async {
    if (_pendingQueue.isEmpty) {
      return {'success': true, 'applied_count': 0, 'message': 'No pending actions to sync.'};
    }

    _isSyncing = true;
    for (final action in _pendingQueue) {
      action.status = 'syncing';
    }

    try {
      final actionsPayload = _pendingQueue.map((a) => a.toJson()).toList();
      final res = await productService.syncBatch(artisanId, actionsPayload);

      if (res['success'] == true || (res['applied_count'] ?? 0) > 0) {
        _pendingQueue.clear();
        await _storage.clear();
      }

      return res;
    } catch (e) {
      for (final action in _pendingQueue) {
        action.retryCount += 1;
        action.status = 'failed';
        action.lastError = e.toString();
      }
      await _persistQueue();
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }
}

