import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/network/api_error.dart';
import '../../core/network/face_profile_api.dart';
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
  bool _faceRegistered = false;
  bool _faceChecked = false;
  bool _isEditing = false;
  bool _isSaving = false;

  // What is shown on screen. Updated right after saving so the page changes at once.
  String _name = '';
  String _phone = '';

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _name = user?.fullName ?? '';
    _phone = user?.phone ?? '';
    _loadGroup();
    _loadFace();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Admins do not check in, so they have no face registration or attendance of their own.
  // To show these for admins too, change this to: bool get _usesAttendance => true;
  bool get _usesAttendance {
    final role = context.read<AuthController>().currentUser?.role.name;
    return role != 'admin';
  }

  Future<void> _loadGroup() async {
    final user = context.read<AuthController>().currentUser;
    if (user?.groupId == null) return;
    try {
      final groups = await GroupApi.getAll();
      final match = groups.where((g) => g.id == user!.groupId).toList();
      if (match.isNotEmpty && mounted) setState(() => _group = match.first);
    } catch (_) {}
  }

  Future<void> _loadFace() async {
    final user = context.read<AuthController>().currentUser;
    if (user == null || !_usesAttendance) return;
    try {
      final profiles = await FaceProfileApi.getByUser(user.id);
      if (mounted) {
        setState(() {
          _faceRegistered = profiles.isNotEmpty;
          _faceChecked = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _faceChecked = true);
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------- edit name and phone ----------
  void _startEditing() {
    _nameController.text = _name;
    _phoneController.text = _phone;
    setState(() => _isEditing = true);
  }

  Future<void> _save() async {
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;

    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();
    if (newName.isEmpty) {
      _toast('Name cannot be empty.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await UserApi.updateUser(user.id, fullName: newName, phone: newPhone);
      if (!mounted) return;
      setState(() {
        _name = newName;
        _phone = newPhone;
        _isEditing = false;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _toast(apiErrorMessage(e, fallback: 'Could not save. Please try again.'));
    }
  }

  // ---------- change password ----------
  Future<void> _openChangePassword() async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change password', style: AppTextStyles.heading),
                const SizedBox(height: 16),
                TextField(
                  controller: oldController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password (at least 8 characters)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm new password'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: AppColors.absent, fontSize: 12.5)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final oldPw = oldController.text;
                            final newPw = newController.text;
                            final confirmPw = confirmController.text;

                            if (oldPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
                              setSheetState(() => error = 'Please fill in every field.');
                              return;
                            }
                            if (newPw.length < 8) {
                              setSheetState(() => error = 'New password must be at least 8 characters.');
                              return;
                            }
                            if (newPw != confirmPw) {
                              setSheetState(() => error = 'The new passwords do not match.');
                              return;
                            }
                            if (newPw == oldPw) {
                              setSheetState(() => error = 'New password must be different from the current one.');
                              return;
                            }

                            setSheetState(() {
                              error = null;
                              isSaving = true;
                            });
                            try {
                              await UserApi.changePassword(oldPassword: oldPw, newPassword: newPw);
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                              if (mounted) _toast('Password updated.');
                            } catch (e) {
                              setSheetState(() {
                                isSaving = false;
                                error = apiErrorMessage(e, fallback: 'Could not change the password.');
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isSaving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Update password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFaceRegistration() async {
    await Navigator.pushNamed(context, AppRoutes.faceRegistration);
    _loadFace(); // refresh the status when the user comes back
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final role = _capitalize(user?.role.name ?? '');
    final team = _group?.name ?? 'Not assigned';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Profile', style: AppTextStyles.heading),
            const SizedBox(height: 18),

            // ---- Header ----
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                    style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name, style: AppTextStyles.heading),
                      const SizedBox(height: 2),
                      Text('$role · $team', style: AppTextStyles.bodySoft),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ---- Details or edit form ----
            if (!_isEditing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _row('Full name', _name),
                    _divider(),
                    _row('Email', user?.email ?? ''),
                    _divider(),
                    _row('Phone', _phone.isEmpty ? 'Not set' : _phone),
                    _divider(),
                    _passwordRow(),
                    _divider(),
                    _row('Team', team),
                    if (_usesAttendance) ...[
                      _divider(),
                      _faceRow(),
                    ],
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Full name', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextField(controller: _nameController, decoration: _inputDecoration()),
                    const SizedBox(height: 14),
                    Text('Phone', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _inputDecoration()),
                    const SizedBox(height: 10),
                    Text('Email and team are managed by your admin.', style: AppTextStyles.bodySoft),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ---- Buttons ----
            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => setState(() => _isEditing = false),
                      style: _outlineStyle(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save'),
                    ),
                  ),
                ],
              )
            else ...[
              OutlinedButton(onPressed: _startEditing, style: _outlineStyle(), child: const Text('Edit profile')),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: _openChangePassword, style: _outlineStyle(), child: const Text('Change password')),
              if (_usesAttendance) ...[
                const SizedBox(height: 10),
                // Not registered yet: "Register my face". Already registered: "Re-register my face".
                if (_faceChecked)
                  OutlinedButton(
                    onPressed: _openFaceRegistration,
                    style: _outlineStyle(),
                    child: Text(_faceRegistered ? 'Re-register my face' : 'Register my face'),
                  ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.attendanceHistory),
                  style: _outlineStyle(plain: true),
                  child: const Text('Attendance history'),
                ),
              ],
              const SizedBox(height: 10),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                  }
                },
                child: const Text('Log out', style: TextStyle(color: AppColors.absent, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- small pieces ----------

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySoft),
          const SizedBox(width: 16),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }

  // The real password is never stored or shown in the app, so this is a fixed mask.
  Widget _passwordRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Password', style: AppTextStyles.bodySoft),
          const Text('••••••••', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _faceRow() {
    final Color fg = _faceRegistered ? AppColors.present : AppColors.late;
    final Color bg = _faceRegistered ? AppColors.presentBg : AppColors.lateBg;
    final String text = !_faceChecked ? 'Checking' : (_faceRegistered ? 'Registered' : 'Not registered yet');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Face', style: AppTextStyles.bodySoft),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
            child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: AppColors.line);

  ButtonStyle _outlineStyle({bool plain = false}) => OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        foregroundColor: plain ? AppColors.ink : AppColors.primary,
        backgroundColor: plain ? AppColors.panel : null,
        side: BorderSide(color: plain ? AppColors.line : AppColors.primary, width: plain ? 1 : 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 14),
      );

  InputDecoration _inputDecoration() => InputDecoration(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.line)),
      );
}