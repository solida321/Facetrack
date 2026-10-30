import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app/theme/app_text_styles.dart';
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
  useMaterial3: true,
  fontFamily: 'Inter',
  fontFamilyFallback: const ['NotoSansKhmer'],
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.panel,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.background,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    titleTextStyle: AppTextStyles.subheading,
    iconTheme: const IconThemeData(color: AppColors.ink),
  ),
  cardTheme: CardThemeData(
    color: AppColors.panel,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: AppColors.line),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(0, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
          fontFamily: 'Sora', fontWeight: FontWeight.w800, fontSize: 16),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryDeep,
      minimumSize: const Size(0, 54),
      side: const BorderSide(color: AppColors.primary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
          fontFamily: 'Sora', fontWeight: FontWeight.w800, fontSize: 16),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryDeep,
      textStyle: const TextStyle(
          fontFamily: 'Sora', fontWeight: FontWeight.w800, fontSize: 14),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.line, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.line, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.absent, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.absent, width: 1.5),
    ),
    hintStyle: const TextStyle(color: AppColors.inkSoft),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: AppColors.primarySoft,
    height: 76,
    labelTextStyle: WidgetStatePropertyAll(const TextStyle(
        fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 11.5)),
  ),
),
        routes: AppRoutes.routes,
        home: FutureBuilder<bool>(
          future: _hasSeenOnboarding(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            return snapshot.data!
                ? const _LoginRedirect()
                : const OnboardingScreen();
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
