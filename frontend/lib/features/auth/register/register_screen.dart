import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/back_circle_button.dart';
import '../../../widgets/info_banner.dart';
import '../../../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _formError; // problem found on the phone, before asking the server

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Returns a sentence for the first problem, or null when everything is fine.
  String? _validate() {
    final name = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (name.length < 2) return 'Please enter your full name.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Please enter a valid email address.';
    if (!RegExp(r'^[0-9+\- ]{8,30}$').hasMatch(phone)) return 'Please enter a valid phone number (8 digits or more).';
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (password != _confirmController.text) return 'The two passwords do not match.';
    return null;
  }

  Future<void> _handleRegister() async {
    final problem = _validate();
    setState(() => _formError = problem);
    if (problem != null) return;

    final auth = context.read<AuthController>();
    final success = await auth.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
    );

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Account created'),
          content: const Text(
            'Your account is pending approval. An admin has been notified and needs to activate it before you can log in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: BackCircleButton(),
              ),
              const SizedBox(height: 20),
              Text('Create your account', style: AppTextStyles.headline),
              const SizedBox(height: 6),
              Text(
                'An admin will approve your account before you can sign in.',
                style: AppTextStyles.bodySoft,
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Full name',
                controller: _fullNameController,
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.mail_outline_rounded,
                hint: 'name@company.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Phone number',
                controller: _phoneController,
                icon: Icons.phone_iphone_rounded,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Password',
                controller: _passwordController,
                icon: Icons.lock_outline_rounded,
                hint: 'At least 8 characters',
                obscure: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Confirm password',
                controller: _confirmController,
                icon: Icons.lock_outline_rounded,
                hint: 'Type your password again',
                obscure: true,
                textInputAction: TextInputAction.done,
              ),
              if (_formError != null || auth.errorMessage != null) ...[
                const SizedBox(height: 16),
                InfoBanner(
                  icon: Icons.error_outline_rounded,
                  title: _formError ?? auth.errorMessage!,
                  tone: BannerTone.bad,
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Create account',
                onPressed: auth.isLoading ? null : _handleRegister,
                isLoading: auth.isLoading,
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Already registered?', style: AppTextStyles.bodySoft),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AppRoutes.login),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}