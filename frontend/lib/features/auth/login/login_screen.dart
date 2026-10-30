import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/info_banner.dart';
import '../../../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    final auth = context.read<AuthController>();
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.face_retouching_natural_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('AttendFace', style: AppTextStyles.heading),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Welcome back',
                    style: AppTextStyles.headline.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to check in and keep track of your attendance.',
                    style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    label: 'Email or phone number',
                    controller: _emailController,
                    icon: Icons.person_outline_rounded,
                    hint: 'name@company.com',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    icon: Icons.lock_outline_rounded,
                    hint: 'Enter your password',
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!auth.isLoading) _handleLogin();
                    },
                  ),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    InfoBanner(
                      icon: Icons.error_outline_rounded,
                      title: auth.errorMessage!,
                      subtitle:
                          'If you just registered, your account may still be pending approval.',
                      tone: BannerTone.bad,
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Sign in',
                    onPressed: auth.isLoading ? null : _handleLogin,
                    isLoading: auth.isLoading,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('New to AttendFace?', style: AppTextStyles.bodySoft),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text('Create account'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded,
                              size: 18, color: AppColors.primaryDeep),
                          const SizedBox(width: 8),
                          Text(
                            'Face verification is required to check in',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}