import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:artisan_mobile/core/constants/api_constants.dart';
import 'package:artisan_mobile/core/network/api_client.dart';

abstract class SecureTokenStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

class FlutterSecureTokenStorage implements SecureTokenStorage {
  final FlutterSecureStorage _storage;
  FlutterSecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}

class InMemoryTokenStorage implements SecureTokenStorage {
  final Map<String, String> _data = {};
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> delete(String key) async => _data.remove(key);
  @override
  Future<void> deleteAll() async => _data.clear();
}


class AuthService extends ChangeNotifier {
  static const String _storageTokenKey = 'artisan_jwt_token';
  static const String _storageUserKey = 'artisan_user_profile';

  final ApiClient _apiClient;
  final SecureTokenStorage _storage;
  String? _token;
  Map<String, dynamic>? _currentUser;
  bool _isRestoring = false;

  ApiClient get apiClient => _apiClient;
  SecureTokenStorage get storage => _storage;
  String? get currentToken => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty && _currentUser != null;
  bool get isProfileComplete => _currentUser?['is_profile_complete'] == true;
  bool get isRestoring => _isRestoring;

  int? get currentArtisanId {
    if (_currentUser == null) return null;
    final val = _currentUser!['artisan_id'];
    if (val is int) return val;
    if (val != null) return int.tryParse(val.toString());
    return null;
  }

  String get currentArtisanName =>
      _currentUser?['full_name']?.toString() ??
      _currentUser?['name']?.toString() ??
      _currentUser?['artisan_name']?.toString() ??
      'Artisan';
  String get currentArtisanPhone => _currentUser?['phone']?.toString() ?? '';
  String? get currentCraftCategory => _currentUser?['craft_category']?.toString();
  String? get currentState => _currentUser?['state']?.toString();
  String? get currentDistrict => _currentUser?['district']?.toString();
  String? get currentPreferredLanguage => _currentUser?['preferred_language']?.toString();

  AuthService({
    ApiClient? apiClient,
    SecureTokenStorage? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ??
            (Platform.environment.containsKey('FLUTTER_TEST')
                ? InMemoryTokenStorage()
                : FlutterSecureTokenStorage()) {
    _apiClient.onUnauthorized = logout;
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  Map<String, dynamic> _buildUserMap(Map<String, dynamic> resMap, {String? defaultPhone}) {
    final isComplete = resMap['is_profile_complete'] == true;
    return {
      'user_id': resMap['user_id'],
      'artisan_id': resMap['artisan_id'],
      'full_name': resMap['name'] ?? resMap['full_name'] ?? 'Artisan User',
      'role': resMap['role'] ?? 'artisan',
      'phone': resMap['phone'] ?? defaultPhone ?? '',
      'is_profile_complete': isComplete,
      'craft_category': resMap['craft_category'] ?? 'Traditional Crafts',
      'state': resMap['state'] ?? 'India',
      'district': resMap['district'] ?? '',
      'preferred_language': resMap['preferred_language'] ?? 'hi',
      'artisan_name': resMap['artisan_name'],
      'artisan_type': resMap['artisan_type'],
      'experience_years': resMap['experience_years'],
      'description': resMap['description'],
      'verified': true,
    };
  }

  /// Saves JWT token to secure persistent storage
  Future<void> saveToken(String token) async {
    _token = token;
    _apiClient.authToken = token;
    await _storage.write(_storageTokenKey, token);
  }

  /// Clears JWT token and user profile from secure storage
  Future<void> clearToken() async {
    _token = null;
    _apiClient.authToken = null;
    await _storage.delete(_storageTokenKey);
    await _storage.delete(_storageUserKey);
  }

  /// Loads saved session token on startup and verifies it with /auth/me.
  /// Persists authentication across app launches until manual logout or explicit 401.
  Future<bool> loadSavedSession() async {
    _isRestoring = true;
    notifyListeners();
    try {
      final savedToken = await _storage.read(_storageTokenKey);
      if (savedToken == null || savedToken.isEmpty) {
        _isRestoring = false;
        notifyListeners();
        return false;
      }

      _token = savedToken;
      _apiClient.authToken = savedToken;

      final savedUserJson = await _storage.read(_storageUserKey);
      if (savedUserJson != null && savedUserJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(savedUserJson) as Map<String, dynamic>;
          _currentUser = decoded;
        } catch (_) {}
      }

      try {
        await getMe();
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          await clearToken();
          _currentUser = null;
          _isRestoring = false;
          notifyListeners();
          return false;
        }
        // If it's a network/offline error, preserve session from cached user profile
      } catch (_) {
        // Preserve cached session when server is temporarily unreachable
      }

      _isRestoring = false;
      notifyListeners();
      return isAuthenticated;
    } catch (_) {
      _isRestoring = false;
      notifyListeners();
      return isAuthenticated;
    }
  }

  /// Restores session on demand
  Future<bool> restoreSession() => loadSavedSession();

  /// Sends OTP request to backend
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final cleanPhone = _normalizePhone(phone);
    final response = await _apiClient.post(
      ApiConstants.authOtpSend,
      body: {'phone': cleanPhone},
    );
    return response as Map<String, dynamic>;
  }

  /// Verifies OTP code, persists JWT token and profile to secure storage, and initializes user
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final cleanPhone = _normalizePhone(phone);
    final response = await _apiClient.post(
      ApiConstants.authOtpVerify,
      body: {'phone': cleanPhone, 'otp': otp.trim()},
    );

    final resMap = response as Map<String, dynamic>;
    final token = resMap['access_token'] as String?;
    if (token != null && token.isNotEmpty) {
      await saveToken(token);
      final userMap = _buildUserMap(resMap, defaultPhone: cleanPhone);
      _currentUser = userMap;
      await _storage.write(_storageUserKey, jsonEncode(userMap));
      notifyListeners();
    }
    return resMap;
  }

  /// Updates profile for authenticated artisan in PostgreSQL
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    if (_token == null || _token!.isEmpty) {
      throw ApiException('Not authenticated', statusCode: 401);
    }
    final response = await _apiClient.put(
      ApiConstants.authProfileUpdate,
      body: profileData,
    );
    final resMap = response as Map<String, dynamic>;
    final userMap = _buildUserMap(resMap);
    _currentUser = userMap;
    await _storage.write(_storageUserKey, jsonEncode(userMap));
    notifyListeners();
    return resMap;
  }

  /// Fetches profile of current authenticated user via JWT
  Future<Map<String, dynamic>> getMe() async {
    if (_token == null || _token!.isEmpty) {
      throw ApiException('Not authenticated', statusCode: 401);
    }
    final response = await _apiClient.get(ApiConstants.authMe);
    final resMap = response as Map<String, dynamic>;
    final userMap = _buildUserMap(resMap);
    _currentUser = userMap;
    await _storage.write(_storageUserKey, jsonEncode(userMap));
    notifyListeners();
    return resMap;
  }

  /// Sets active session explicitly and persists token & profile
  void setSession({required String token, required Map<String, dynamic> user}) {
    _token = token;
    _apiClient.authToken = token;
    _currentUser = Map<String, dynamic>.from(user);
    _storage.write(_storageTokenKey, token);
    _storage.write(_storageUserKey, jsonEncode(_currentUser));
    notifyListeners();
  }

  /// Logs out user, clears token and profile from secure storage, and invalidates in-memory session
  void logout() {
    clearToken();
    _currentUser = null;
    notifyListeners();
  }
}


