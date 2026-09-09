import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/services/product_service.dart';

void main() {
  group('Auth Service Tests', () {
    test('sendOtp triggers OTP send endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/auth/otp/send');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['phone'], '+919876543210');

        return http.Response(
          jsonEncode({
            'success': true,
            'phone': '+919876543210',
            'otp_code': '123456',
            'message': 'OTP sent successfully (Demo mock: 123456)',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ProductService(apiClient: ApiClient(client: mockClient));
      final result = await service.sendOtp('+919876543210');

      expect(result['success'], isTrue);
      expect(result['otp_code'], equals('123456'));
    });

    test('verifyOtp returns access token and user info', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/auth/otp/verify');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['phone'], '+919876543210');
        expect(body['otp'], '123456');

        return http.Response(
          jsonEncode({
            'access_token': 'mock_jwt_token_123',
            'token_type': 'bearer',
            'user': {
              'phone': '+919876543210',
              'full_name': 'Meera Devi',
              'role': 'artisan',
              'craft_category': 'Pottery & Terracotta',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ProductService(apiClient: ApiClient(client: mockClient));
      final result = await service.verifyOtp('+919876543210', '123456');

      expect(result['access_token'], equals('mock_jwt_token_123'));
      expect(result['user']['full_name'], equals('Meera Devi'));
      expect(result['user']['role'], equals('artisan'));
    });

    test('login with password returns JWT token', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/auth/login');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['phone'], '+919876543210');
        expect(body['password'], 'ArtisanSecret123');

        return http.Response(
          jsonEncode({
            'access_token': 'mock_jwt_token_456',
            'token_type': 'bearer',
            'user': {
              'phone': '+919876543210',
              'full_name': 'Meera Devi',
              'role': 'artisan',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ProductService(apiClient: ApiClient(client: mockClient));
      final result = await service.login('+919876543210', 'ArtisanSecret123');

      expect(result['access_token'], equals('mock_jwt_token_456'));
      expect(result['user']['role'], equals('artisan'));
    });

    test('ApiClient automatically attaches Authorization Bearer header when token is set', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], equals('Bearer test_jwt_token_xyz'));
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final apiClient = ApiClient(client: mockClient, authToken: 'test_jwt_token_xyz');
      final res = await apiClient.get('http://127.0.0.1:8000/auth/me');
      expect(res['status'], equals('ok'));

      // Test dynamically setting authToken
      apiClient.authToken = 'updated_token_abc';
      expect(apiClient.authToken, equals('updated_token_abc'));
    });
  });
}
