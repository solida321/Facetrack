import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/routes/app_routes.dart';
import 'app/theme/app_colors.dart';
import 'core/controllers/auth_controller.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() {
  runApp(const FaceTrackApp());
}

class FaceTrackApp extends StatelessWidget {
  const FaceTrackApp({super.key});

  Future<bool> _hasSeenOnboarding() async {
    const storage = FlutterSecureStorage();
    final value = await storage.read(key: 'onboarding_seen');
    return value == 'true';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: MaterialApp(
        title: 'FaceTrack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Inter',
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            surface: AppColors.background,
          ),
          useMaterial3: true,
        ),
        routes: AppRoutes.routes,
        home: FutureBuilder<bool>(
          future: _hasSeenOnboarding(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }
            return snapshot.data! ? const _LoginRedirect() : const OnboardingScreen();
          },
        ),
      ),
    );
  }
}

class _LoginRedirect extends StatelessWidget {
  const _LoginRedirect();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
    return const Scaffold(backgroundColor: AppColors.background);
  }
}