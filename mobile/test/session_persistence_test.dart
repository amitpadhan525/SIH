import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/services/auth_service.dart';

void main() {
  group('Secure JWT Session Persistence Tests', () {
    test('Saves token to SecureTokenStorage on verifyOtp and restores session on loadSavedSession', () async {
      final storage = InMemoryTokenStorage();

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/auth/otp/verify')) {
          return http.Response(
            jsonEncode({
              'access_token': 'secure_jwt_token_123',
              'user_id': 42,
              'artisan_id': 42,
              'name': 'Radha Devi',
              'phone': '+919876543210',
              'role': 'artisan',
              'is_profile_complete': true,
              'craft_category': 'Madhubani Painting',
              'state': 'Bihar',
              'district': 'Madhubani',
            }),
            200,
          );
        } else if (request.url.path.contains('/auth/me')) {
          if (request.headers['Authorization'] == 'Bearer secure_jwt_token_123') {
            return http.Response(
              jsonEncode({
                'user_id': 42,
                'artisan_id': 42,
                'name': 'Radha Devi',
                'phone': '+919876543210',
                'role': 'artisan',
                'is_profile_complete': true,
                'craft_category': 'Madhubani Painting',
                'state': 'Bihar',
                'district': 'Madhubani',
              }),
              200,
            );
          }
          return http.Response('{"detail": "Unauthorized"}', 401);
        }
        return http.Response('{"detail": "Not found"}', 404);
      });

      final authService1 = AuthService(
        apiClient: ApiClient(client: mockClient),
        storage: storage,
      );

      // Verify OTP and check token saved in storage
      await authService1.verifyOtp('+919876543210', '123456');
      expect(authService1.isAuthenticated, isTrue);
      expect(await storage.read('artisan_jwt_token'), equals('secure_jwt_token_123'));

      // Simulate App Restart with new AuthService instance using the same persistent storage
      final authService2 = AuthService(
        apiClient: ApiClient(client: mockClient),
        storage: storage,
      );

      expect(authService2.isAuthenticated, isFalse);

      final restored = await authService2.loadSavedSession();
      expect(restored, isTrue);
      expect(authService2.isAuthenticated, isTrue);
      expect(authService2.currentArtisanName, equals('Radha Devi'));
      expect(authService2.isProfileComplete, isTrue);
    });

    test('Expired/Invalid token clears secure storage on loadSavedSession', () async {
      final storage = InMemoryTokenStorage();
      await storage.write('artisan_jwt_token', 'expired_or_invalid_jwt');

      final mockClient = MockClient((request) async {
        return http.Response('{"detail": "Token expired"}', 401);
      });

      final authService = AuthService(
        apiClient: ApiClient(client: mockClient),
        storage: storage,
      );

      final restored = await authService.loadSavedSession();
      expect(restored, isFalse);
      expect(authService.isAuthenticated, isFalse);
      expect(await storage.read('artisan_jwt_token'), isNull);
    });

    test('Offline or network failure on loadSavedSession preserves cached session', () async {
      final storage = InMemoryTokenStorage();
      await storage.write('artisan_jwt_token', 'cached_jwt_token_888');
      await storage.write(
        'artisan_user_profile',
        jsonEncode({
          'user_id': 88,
          'artisan_id': 88,
          'name': 'Lakshmi Devi',
          'phone': '+919123456780',
          'role': 'artisan',
          'is_profile_complete': true,
          'craft_category': 'Wood Carving',
        }),
      );

      final mockClient = MockClient((request) async {
        throw Exception('No internet connection');
      });

      final authService = AuthService(
        apiClient: ApiClient(client: mockClient),
        storage: storage,
      );

      final restored = await authService.loadSavedSession();
      expect(restored, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentArtisanName, equals('Lakshmi Devi'));
      expect(authService.currentArtisanPhone, equals('+919123456780'));
      expect(authService.isProfileComplete, isTrue);
      expect(await storage.read('artisan_jwt_token'), equals('cached_jwt_token_888'));
    });

    test('Logout clears session from secure storage', () async {
      final storage = InMemoryTokenStorage();
      await storage.write('artisan_jwt_token', 'active_token_999');
      await storage.write('artisan_user_profile', '{"name":"Artisan"}');

      final authService = AuthService(storage: storage);
      authService.logout();

      expect(authService.isAuthenticated, isFalse);
      expect(await storage.read('artisan_jwt_token'), isNull);
      expect(await storage.read('artisan_user_profile'), isNull);
    });
  });
}
