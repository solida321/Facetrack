import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/routes/app_routes.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/network/group_api.dart';
import '../../core/network/user_api.dart';
import '../../data/models/group_model.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  GroupModel? _group;
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) return;
    _nameController.text = user.fullName;
    _phoneController.text = user.phone ?? '';

    if (user.groupId == null) return;
    try {
      final groups = await GroupApi.getAll();
      final match = groups.where((g) => g.id == user.groupId).toList();
      if (match.isNotEmpty && mounted) setState(() => _group = match.first);
    } catch (_) {}
  }

  Future<void> _save() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) return;
    await UserApi.updateUser(
      user.id,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'bloom',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Your space.', style: AppTextStyles.heading),
              const SizedBox(height: 3),
              Text(
                'Your account, preferences and work details',
                style: AppTextStyles.bodySoft,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: AppColors.panel,
                      child: Text(
                        user?.fullName.isNotEmpty == true
                            ? user!.fullName[0]
                            : '?',
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? '',
                            style: AppTextStyles.subheading,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${user?.role.name ?? ''} · ${_group?.name ?? 'No group assigned'}',
                            style: AppTextStyles.bodySoft,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Work details', style: AppTextStyles.subheading),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _detailRow('Email', user?.email ?? ''),
                    const Divider(height: 1, color: AppColors.line),
                    _detailRow('Group', _group?.name ?? 'No group assigned'),
                    if ((user?.phone ?? '').isNotEmpty) ...[
                      const Divider(height: 1, color: AppColors.line),
                      _detailRow('Phone', user!.phone!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_isEditing) ...[
                Text('Edit profile', style: AppTextStyles.subheading),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _isEditing = false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ] else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Edit profile'),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkSoft,
                    ),
                    onTap: () => setState(() => _isEditing = true),
                  ),
                ),
              const SizedBox(height: 12),
              Text('My records', style: AppTextStyles.subheading),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Attendance history'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.inkSoft,
                  ),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.attendanceHistory,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 17),
                  label: const Text('Log out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySoft),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
