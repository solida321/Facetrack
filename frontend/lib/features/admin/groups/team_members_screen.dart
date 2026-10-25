import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/group_api.dart';
import '../../../core/network/role_api.dart';
import '../../../core/network/user_api.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/role_model.dart';
import '../../../data/models/user_model.dart';

class TeamMembersScreen extends StatefulWidget {
  final GroupModel group;
  const TeamMembersScreen({super.key, required this.group});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  List<UserModel> _members = [];
  List<GroupModel> _groups = [];
  List<RoleModel> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await UserApi.getAll();
      final groups = await GroupApi.getAll();
      final roles = await RoleApi.getAll();
      if (!mounted) return;
      setState(() {
        _members = users.where((u) => u.groupId == widget.group.id).toList();
        _groups = groups;
        _roles = roles;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------- delete ----------
  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
          'This permanently deletes ${user.fullName}. If they have attendance history, deleting may fail. Use Deactivate on the Users tab instead.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.absent)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await UserApi.delete(user.id);
      _load();
    } catch (e) {
      if (mounted) {
        _toast(apiErrorMessage(e, fallback: 'Could not delete. This user may have attendance history. Try Deactivate instead.'));
      }
    }
  }

  // ---------- move to another team ----------
  Future<void> _moveUser(UserModel user) async {
    final others = _groups.where((g) => g.id != widget.group.id).toList();
    if (others.isEmpty) {
      _toast('There is no other team to move to.');
      return;
    }
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Move ${user.fullName} to'),
        children: others
            .map((g) => SimpleDialogOption(onPressed: () => Navigator.pop(context, g.id), child: Text(g.name)))
            .toList(),
      ),
    );
    if (selected == null) return;
    try {
      await UserApi.updateUser(user.id, groupId: selected);
      _load();
    } catch (e) {
      if (mounted) _toast(apiErrorMessage(e, fallback: 'Could not move this user.'));
    }
  }

  // ---------- add a new user straight into this team ----------
  Future<void> _openCreateForm() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    // Pre-select the "employee" role when it exists.
    final employeeRole = _roles.where((r) => r.name == 'employee').toList();
    int? roleId = employeeRole.isNotEmpty ? employeeRole.first.id : null;
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
                Text('Add to ${widget.group.name}', style: AppTextStyles.heading),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password (at least 8 characters)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: roleId,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: _roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                  onChanged: (v) => setSheetState(() => roleId = v),
                ),
                const SizedBox(height: 12),
                Text('Team: ${widget.group.name}', style: AppTextStyles.bodySoft),
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
                            final name = nameController.text.trim();
                            final email = emailController.text.trim();
                            final password = passwordController.text;

                            if (name.isEmpty || email.isEmpty || password.isEmpty || roleId == null) {
                              setSheetState(() => error = 'Please fill in every field.');
                              return;
                            }
                            if (!email.contains('@')) {
                              setSheetState(() => error = 'Enter a valid email address.');
                              return;
                            }
                            if (password.length < 8) {
                              setSheetState(() => error = 'Password must be at least 8 characters.');
                              return;
                            }

                            setSheetState(() {
                              error = null;
                              isSaving = true;
                            });
                            try {
                              await UserApi.create(
                                fullName: name,
                                email: email,
                                password: password,
                                roleId: roleId!,
                                groupId: widget.group.id,
                              );
                              await _load();
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                            } catch (e) {
                              setSheetState(() {
                                isSaving = false;
                                error = apiErrorMessage(e, fallback: 'Could not create this user.');
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isSaving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Create'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.group.name, style: AppTextStyles.headline),
            Text(_members.length == 1 ? '1 person' : '${_members.length} people', style: AppTextStyles.bodySoft),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add user to this team',
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
            onPressed: _openCreateForm,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _members.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('No one is in this team yet.', style: AppTextStyles.bodySoft),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _openCreateForm,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          child: const Text('Add the first person'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _members.length,
                    itemBuilder: (context, i) => _memberCard(_members[i]),
                  ),
                ),
    );
  }

  Widget _memberCard(UserModel u) {
    final active = u.status == 'active';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.fullName, style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 12.5)),
                      Text('${u.role.name} · ${u.email}', style: AppTextStyles.bodySoft, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? AppColors.presentBg : AppColors.lateBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    u.status,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: active ? AppColors.present : AppColors.late),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => _moveUser(u), child: const Text('Move')),
                TextButton(
                  onPressed: () => _deleteUser(u),
                  child: const Text('Delete', style: TextStyle(color: AppColors.absent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}