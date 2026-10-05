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
    await UserApi.updateUser(user.id, fullName: _nameController.text.trim(), phone: _phoneController.text.trim());
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32, backgroundColor: AppColors.primarySoft,
                child: Text(
                  user?.fullName.isNotEmpty == true ? user!.fullName[0] : '?',
                  style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 20),
                ),
              ),
              const SizedBox(height: 12),

              if (!_isEditing) ...[
                Text(user?.fullName ?? '', style: AppTextStyles.heading),
                Text(user?.email ?? '', style: AppTextStyles.bodySoft),
                const SizedBox(height: 4),
                Text('${user?.role.name ?? ''} · ${_group?.name ?? 'No group assigned'}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
              ] else ...[
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 10),
                TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              ],

              const SizedBox(height: 24),

              if (!_isEditing)
                ListTile(
                  title: const Text('Edit profile'),
                  onTap: () => setState(() => _isEditing = true),
                )
              else
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Cancel'))),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(onPressed: _save, child: const Text('Save'))),
                  ],
                ),

              ListTile(
                title: const Text('Log out', style: TextStyle(color: AppColors.absent)),
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}