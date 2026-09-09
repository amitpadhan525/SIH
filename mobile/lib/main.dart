import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/screens/auth/complete_profile_screen.dart';
import 'package:artisan_mobile/screens/auth/login_screen.dart';
import 'package:artisan_mobile/screens/home/home_screen.dart';
import 'package:artisan_mobile/services/auth_service.dart';
import 'package:artisan_mobile/services/product_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  // Restore persisted session from secure storage on app launch
  await authService.loadSavedSession();
  final productService = ProductService(apiClient: authService.apiClient);
  runApp(ArtisanApp(authService: authService, productService: productService));
}

class ArtisanApp extends StatelessWidget {
  final AuthService? authService;
  final ProductService? productService;

  const ArtisanApp({super.key, this.authService, this.productService});

  @override
  Widget build(BuildContext context) {
    final activeAuth = authService ?? AuthService();
    final activeProduct = productService ?? ProductService(apiClient: activeAuth.apiClient);

    return MaterialApp(
      title: 'Artisan Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AuthGate(
        authService: activeAuth,
        productService: activeProduct,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final AuthService authService;
  final ProductService productService;

  const AuthGate({
    super.key,
    required this.authService,
    required this.productService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        if (authService.isRestoring) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!authService.isAuthenticated) {
          return LoginScreen(
            authService: authService,
          );
        }

        if (!authService.isProfileComplete) {
          return CompleteProfileScreen(
            authService: authService,
          );
        }

        return HomeScreen(
          authService: authService,
          productService: productService,
        );
      },
    );
  }
}
