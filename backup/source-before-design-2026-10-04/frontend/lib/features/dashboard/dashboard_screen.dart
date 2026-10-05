import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/controllers/auth_controller.dart';
import '../../core/network/face_profile_api.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideNextScreen());
  }

  Future<void> _decideNextScreen() async {
    final auth = context.read<AuthController>();
    final roleName = auth.currentUser?.role.name;

    // First-time check: has this user registered their face yet?
    try {
      final faceProfiles = await FaceProfileApi.getByUser(auth.currentUser!.id);
      if (faceProfiles.isEmpty && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.faceRegistration);
        return;
      }
    } catch (e) {
      // If this check fails (e.g. endpoint not ready yet), fall through
      // to normal routing rather than blocking the user entirely.
    }

    if (!mounted) return;

    switch (roleName) {
      case 'admin':
        Navigator.pushReplacementNamed(context, AppRoutes.adminShell);
        break;
      case 'manager':
        Navigator.pushReplacementNamed(context, AppRoutes.managerShell);
        break;
      case 'employee':
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.employeeShell);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}