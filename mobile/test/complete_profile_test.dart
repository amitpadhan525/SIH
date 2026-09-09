import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/main.dart';
import 'package:artisan_mobile/screens/auth/complete_profile_screen.dart';
import 'package:artisan_mobile/services/auth_service.dart';
import 'package:artisan_mobile/services/product_service.dart';

void main() {
  group('CompleteProfileScreen & AuthGate Navigation Tests', () {
    testWidgets('AuthGate displays CompleteProfileScreen when authenticated but profile is incomplete', (WidgetTester tester) async {
      final mockClient = MockClient((request) async => http.Response(jsonEncode({}), 200));
      final authService = AuthService(apiClient: ApiClient(client: mockClient));
      final productService = ProductService(apiClient: authService.apiClient);

      // Authenticate with incomplete profile (new user)
      authService.setSession(
        token: 'new_user_token',
        user: {
          'user_id': 100,
          'artisan_id': 100,
          'full_name': 'Artisan 9999',
          'phone': '+919999999999',
          'is_profile_complete': false,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            authService: authService,
            productService: productService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Complete Your Profile'), findsOneWidget);
      expect(find.text('Step 2: Tell Us About Your Craft'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Craft Category *'), findsOneWidget);
      expect(find.text('Save & Enter Studio'), findsOneWidget);
    });

    testWidgets('CompleteProfileScreen validates empty full name', (WidgetTester tester) async {
      final mockClient = MockClient((request) async => http.Response(jsonEncode({}), 200));
      final authService = AuthService(apiClient: ApiClient(client: mockClient));
      authService.setSession(
        token: 'test_token',
        user: {
          'user_id': 1,
          'artisan_id': 1,
          'full_name': 'Artisan 1234',
          'is_profile_complete': false,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CompleteProfileScreen(authService: authService),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Save without entering name
      await tester.ensureVisible(find.text('Save & Enter Studio'));
      await tester.tap(find.text('Save & Enter Studio'));
      await tester.pumpAndSettle();

      expect(find.text('Full Name is required'), findsOneWidget);
    });

    testWidgets('CompleteProfileScreen successfully submits profile and transitions to complete state', (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth/me/profile' && request.method == 'PUT') {
          final body = jsonDecode(request.body);
          expect(body['full_name'], 'Lakshmi Behera');
          expect(body['craft_category'], 'Handloom');
          expect(body['state'], 'Odisha');
          expect(body['district'], 'Bargarh');

          return http.Response(
            jsonEncode({
              'access_token': 'updated_token',
              'user_id': 100,
              'artisan_id': 100,
              'name': 'Lakshmi Behera',
              'role': 'artisan',
              'phone': '+919999999999',
              'is_profile_complete': true,
              'craft_category': 'Handloom',
              'state': 'Odisha',
              'district': 'Bargarh',
              'preferred_language': 'Odia',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(jsonEncode({}), 200);
      });

      final authService = AuthService(apiClient: ApiClient(client: mockClient));
      authService.setSession(
        token: 'active_token',
        user: {
          'user_id': 100,
          'artisan_id': 100,
          'full_name': 'Artisan 9999',
          'phone': '+919999999999',
          'is_profile_complete': false,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CompleteProfileScreen(authService: authService),
        ),
      );

      await tester.pumpAndSettle();

      // Enter name
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Lakshmi Behera');
      await tester.pumpAndSettle();

      // Save
      await tester.ensureVisible(find.text('Save & Enter Studio'));
      await tester.tap(find.text('Save & Enter Studio'));
      await tester.pumpAndSettle();

      expect(authService.isProfileComplete, isTrue);
      expect(authService.currentArtisanName, equals('Lakshmi Behera'));
    });

    testWidgets('CompleteProfileScreen logout button clears session', (WidgetTester tester) async {
      final authService = AuthService();
      authService.setSession(
        token: 'logout_token',
        user: {
          'user_id': 1,
          'artisan_id': 1,
          'full_name': 'Artisan 1234',
          'is_profile_complete': false,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CompleteProfileScreen(authService: authService),
        ),
      );

      await tester.pumpAndSettle();

      // Tap logout in AppBar
      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      expect(authService.isAuthenticated, isFalse);
    });
  });
}
