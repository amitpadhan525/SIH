import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/main.dart';
import 'package:artisan_mobile/screens/auth/complete_profile_screen.dart';
import 'package:artisan_mobile/screens/profile/edit_profile_screen.dart';
import 'package:artisan_mobile/services/auth_service.dart';
import 'package:artisan_mobile/services/product_service.dart';

void main() {
  group('CompleteProfileScreen & AuthGate Navigation Tests', () {
    testWidgets('AuthGate displays simplified CompleteProfileScreen when authenticated but profile is incomplete', (WidgetTester tester) async {
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

      expect(find.text('Tell Us About You'), findsWidgets);
      expect(find.text('Just a few details to personalize your Artisan Studio.'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('What do you make? *'), findsOneWidget);
      expect(find.text('Preferred Language *'), findsOneWidget);
      expect(find.text('Continue to Artisan Studio →'), findsOneWidget);
      // Optional fields should NOT be present on the onboarding screen
      expect(find.text('State *'), findsNothing);
      expect(find.text('District *'), findsNothing);
      expect(find.text('Years of Experience'), findsNothing);
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

      // Tap Continue without entering name
      await tester.ensureVisible(find.text('Continue to Artisan Studio →'));
      await tester.tap(find.text('Continue to Artisan Studio →'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOneWidget);
    });

    testWidgets('CompleteProfileScreen successfully submits 3 fields and transitions to complete state', (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth/me/profile' && request.method == 'PUT') {
          final body = jsonDecode(request.body);
          expect(body['full_name'], 'Sunita Devi');
          expect(body['craft_category'], 'Handloom');
          expect(body['preferred_language'], 'Odia');

          return http.Response(
            jsonEncode({
              'access_token': 'updated_token',
              'user_id': 100,
              'artisan_id': 100,
              'name': 'Sunita Devi',
              'role': 'artisan',
              'phone': '+919999999999',
              'is_profile_complete': true,
              'craft_category': 'Handloom',
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
      await tester.enterText(nameField, 'Sunita Devi');
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(find.text('Continue to Artisan Studio →'));
      await tester.tap(find.text('Continue to Artisan Studio →'));
      await tester.pumpAndSettle();

      expect(authService.isProfileComplete, isTrue);
      expect(authService.currentArtisanName, equals('Sunita Devi'));
    });

    testWidgets('EditProfileScreen allows updating location and optional business details', (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth/me/profile' && request.method == 'PUT') {
          final body = jsonDecode(request.body);
          expect(body['full_name'], 'Sunita Devi');
          expect(body['state'], 'Odisha');
          expect(body['artisan_name'], 'Sambalpuri Weaves');

          return http.Response(
            jsonEncode({
              'access_token': 'updated_token',
              'user_id': 100,
              'artisan_id': 100,
              'name': 'Sunita Devi',
              'role': 'artisan',
              'phone': '+919999999999',
              'is_profile_complete': true,
              'craft_category': 'Handloom',
              'state': 'Odisha',
              'district': 'Sambalpur',
              'artisan_name': 'Sambalpuri Weaves',
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
          'full_name': 'Sunita Devi',
          'phone': '+919999999999',
          'is_profile_complete': true,
          'craft_category': 'Handloom',
          'preferred_language': 'Odia',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileScreen(authService: authService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Basic Details'), findsOneWidget);
      expect(find.text('Location Details'), findsOneWidget);
      expect(find.text('Craft & Experience (Optional)'), findsOneWidget);

      // Enter brand name in optional field
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(1), 'Sambalpuri Weaves');
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(authService.currentDistrict, equals('Sambalpur'));
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
