import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/main.dart';
import 'package:artisan_mobile/screens/auth/login_screen.dart';
import 'package:artisan_mobile/services/auth_service.dart';
import 'package:artisan_mobile/services/product_service.dart';

void main() {
  group('AuthService Unit Tests', () {
    test('sendOtp triggers /auth/otp/send and returns demo OTP', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/auth/otp/send');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['phone'], '+919876543210');

        return http.Response(
          jsonEncode({
            'phone': '+919876543210',
            'demo_otp': '654321',
            'message': 'OTP successfully sent to +919876543210. (Demo code: 654321)',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(apiClient: ApiClient(client: mockClient));
      final result = await authService.sendOtp('+91 9876543210');

      expect(result['demo_otp'], equals('654321'));
      expect(result['phone'], equals('+919876543210'));
    });

    test('verifyOtp initializes session, stores JWT, and marks user authenticated', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/auth/otp/verify');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['phone'], '+919876543210');
        expect(body['otp'], '654321');

        return http.Response(
          jsonEncode({
            'access_token': 'jwt_test_token_abc_123',
            'token_type': 'bearer',
            'user_id': 42,
            'artisan_id': 10,
            'name': 'Radha Bai',
            'role': 'artisan',
            'phone': '+919876543210',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final authService = AuthService(apiClient: apiClient);

      expect(authService.isAuthenticated, isFalse);

      final res = await authService.verifyOtp('+919876543210', '654321');

      expect(res['access_token'], equals('jwt_test_token_abc_123'));
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentToken, equals('jwt_test_token_abc_123'));
      expect(apiClient.authToken, equals('jwt_test_token_abc_123'));
      expect(authService.currentArtisanId, equals(10));
      expect(authService.currentArtisanName, equals('Radha Bai'));
    });

    test('logout resets session, token, and authentication state', () async {
      final authService = AuthService();
      authService.setSession(
        token: 'active_token',
        user: {'user_id': 1, 'artisan_id': 1, 'full_name': 'Test Artisan'},
      );

      expect(authService.isAuthenticated, isTrue);
      expect(authService.apiClient.authToken, equals('active_token'));

      authService.logout();

      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentToken, isNull);
      expect(authService.currentUser, isNull);
      expect(authService.apiClient.authToken, isNull);
    });

    test('ApiClient automatically attaches Authorization header and triggers onUnauthorized on 401', () async {
      int unauthorizedCallCount = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/protected') {
          expect(request.headers['Authorization'], equals('Bearer valid_jwt_token'));
          return http.Response(jsonEncode({'detail': 'Session expired'}), 401);
        }
        return http.Response(jsonEncode({}), 200);
      });

      final apiClient = ApiClient(
        client: mockClient,
        authToken: 'valid_jwt_token',
        onUnauthorized: () {
          unauthorizedCallCount++;
        },
      );

      try {
        await apiClient.get('http://127.0.0.1:8000/protected');
      } catch (e) {
        expect(e is ApiException, isTrue);
      }

      expect(unauthorizedCallCount, equals(1));
      expect(apiClient.authToken, isNull);
    });
  });

  group('AuthGate & LoginScreen Widget Tests', () {
    testWidgets('AuthGate displays LoginScreen when unauthenticated', (WidgetTester tester) async {
      final mockClient = MockClient((request) async => http.Response(jsonEncode({}), 200));
      final authService = AuthService(apiClient: ApiClient(client: mockClient));
      final productService = ProductService(apiClient: authService.apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            authService: authService,
            productService: productService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Artisan Authentication 🌾'), findsOneWidget);
      expect(find.text('Request OTP Code'), findsOneWidget);
      expect(find.text('Namaste'), findsNothing);
    });

    testWidgets('AuthGate transitions to HomeScreen when session is established', (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/health/db') {
          return http.Response(jsonEncode({'database': 'connected'}), 200);
        }
        return http.Response(jsonEncode([]), 200);
      });

      final authService = AuthService(apiClient: ApiClient(client: mockClient));
      final productService = ProductService(apiClient: authService.apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            authService: authService,
            productService: productService,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Artisan Authentication 🌾'), findsOneWidget);

      // Authenticate with complete profile
      authService.setSession(
        token: 'mock_token',
        user: {
          'user_id': 1,
          'artisan_id': 1,
          'full_name': 'Meera Devi',
          'phone': '+919876543210',
          'is_profile_complete': true,
        },
      );

      await tester.pumpAndSettle();

      expect(find.text('Namaste, Meera Devi 🙏'), findsOneWidget);
      expect(find.text('Add New Product'), findsOneWidget);
    });

    testWidgets('LoginScreen full phone OTP request and verify widget flow', (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth/otp/send') {
          return http.Response(
            jsonEncode({
              'phone': '+919876543210',
              'demo_otp': '789123',
              'message': 'OTP sent',
            }),
            200,
          );
        }
        if (request.url.path == '/auth/otp/verify') {
          return http.Response(
            jsonEncode({
              'access_token': 'jwt_success_flow',
              'user_id': 9,
              'artisan_id': 9,
              'name': 'Gita Devi',
              'role': 'artisan',
              'phone': '+919876543210',
            }),
            200,
          );
        }
        return http.Response(jsonEncode({}), 200);
      });

      final authService = AuthService(apiClient: ApiClient(client: mockClient));

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: authService),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Request OTP Code
      await tester.tap(find.text('Request OTP Code'));
      await tester.pumpAndSettle();

      expect(find.text('Server Demo OTP: 789123'), findsOneWidget);
      expect(find.text('Verify OTP & Login'), findsOneWidget);

      // Fill and Verify OTP
      await tester.ensureVisible(find.text('Fill OTP'));
      await tester.tap(find.text('Fill OTP'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Verify OTP & Login'));
      await tester.tap(find.text('Verify OTP & Login'));
      await tester.pumpAndSettle();

      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentArtisanName, equals('Gita Devi'));
    });
  });
}
