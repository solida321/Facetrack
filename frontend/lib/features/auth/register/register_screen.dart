import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/controllers/auth_controller.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create account', style: AppTextStyles.heading),
              const SizedBox(height: 6),
              Text('Shown only if you\'re not registered yet.', style: AppTextStyles.bodySoft),
              const SizedBox(height: 26),

              _buildField('Full name', _fullNameController),
              const SizedBox(height: 14),
              _buildField('Email', _emailController),
              const SizedBox(height: 14),
              _buildField('Phone number', _phoneController),
              const SizedBox(height: 14),
              _buildField('Password (at least 8 characters)', _passwordController, obscure: true),
              const SizedBox(height: 14),
              _buildField('Confirm password', _confirmController, obscure: true),

              if (_formError != null || auth.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(_formError ?? auth.errorMessage!, style: const TextStyle(color: AppColors.absent, fontSize: 12)),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create account', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: RichText(
                    text: const TextSpan(
                      text: "Already registered? ",
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
                      children: [
                        TextSpan(
                          text: 'Sign in',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.line),
            ),
          ),
        ),
      ],
    );
  }
}