import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/user_api.dart';
import '../../../core/network/group_api.dart';
import '../../../core/network/role_api.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/role_model.dart';
import '../../../widgets/filter_chip_group.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  List<GroupModel> _groups = [];
  List<RoleModel> _roles = [];
  bool _isLoading = true;

  int? _roleFilter;
  int? _teamFilter;
  String? _statusFilter; // 'active' | 'pending_approval'
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _search = _searchController.text.trim().toLowerCase()));
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await UserApi.getAll();
      final groups = await GroupApi.getAll();
      final roles = await RoleApi.getAll();
      setState(() { _users = users; _groups = groups; _roles = roles; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<UserModel> get _filtered {
    return _users.where((u) {
      if (_roleFilter != null && u.role.id != _roleFilter) return false;
      if (_teamFilter != null && u.groupId != _teamFilter) return false;
      if (_statusFilter != null && u.status != _statusFilter) return false;
      if (_search.isNotEmpty &&
          !u.fullName.toLowerCase().contains(_search) &&
          !u.email.toLowerCase().contains(_search)) {return false;}
      return true;
    }).toList();
  }

  Future<void> _assignGroup(UserModel user) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Assign team'),
        children: _groups.map((g) {
          final isCurrent = g.id == user.groupId;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, g.id),
            child: Row(children: [
              if (isCurrent) const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
              if (isCurrent) const SizedBox(width: 8),
              Text(g.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400)),
            ]),
          );
        }).toList(),
      ),
    );
    if (selected != null) {
      await UserApi.updateUser(user.id, groupId: selected);
      _load();
    }
  }

  Future<void> _assignRole(UserModel user) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Assign role'),
        children: _roles.map((r) {
          final isCurrent = r.id == user.role.id;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, r.id),
            child: Row(children: [
              if (isCurrent) const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
              if (isCurrent) const SizedBox(width: 8),
              Text(r.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400)),
            ]),
          );
        }).toList(),
      ),
    );
    if (selected != null) {
      await UserApi.updateUser(user.id, roleId: selected);
      _load();
    }
  }

  Future<void> _activate(UserModel user) async {
    await UserApi.updateUser(user.id, status: 'active');
    _load();
  }

  Future<void> _deactivate(UserModel user) async {
    await UserApi.updateUser(user.id, status: 'inactive');
    _load();
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text('This permanently deletes ${user.fullName}. If they have attendance history, this may fail — consider Deactivate instead.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.absent))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await UserApi.delete(user.id);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete — this user has attendance history. Try Deactivate instead.')),
          );
        }
      }
    }
  }

  Future<void> _openCreateForm() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    int? roleId;
    int? groupId;
    String createStatus = 'active';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create user', style: AppTextStyles.heading),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 12),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: roleId,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: _roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                  onChanged: (v) => setSheetState(() => roleId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: groupId,
                  decoration: const InputDecoration(labelText: 'Team (optional)'),
                  items: _groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                  onChanged: (v) => setSheetState(() => groupId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: createStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'pending_approval', child: Text('Pending approval')),
                  ],
                  onChanged: (v) => setSheetState(() => createStatus = v ?? 'active'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty ||
                          emailController.text.trim().isEmpty ||
                          passwordController.text.isEmpty ||
                          roleId == null) {
                        return;
                      }
                      await UserApi.create(
                        fullName: nameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        roleId: roleId!,
                        groupId: groupId,
                      );
                      _load();
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _groupName(int? groupId) {
    if (groupId == null) return 'No team';
    final match = _groups.where((g) => g.id == groupId).toList();
    return match.isNotEmpty ? match.first.name : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Users', style: AppTextStyles.heading),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: _openCreateForm),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                FilterChipGroup<int>(
                  label: 'Role',
                  options: _roles.map((r) => MapEntry(r.name, r.id)).toList(),
                  selected: _roleFilter,
                  onChanged: (v) => setState(() => _roleFilter = v),
                ),
                const SizedBox(height: 14),
                FilterChipGroup<int>(
                  label: 'Team',
                  options: _groups.map((g) => MapEntry(g.name, g.id)).toList(),
                  selected: _teamFilter,
                  onChanged: (v) => setState(() => _teamFilter = v),
                ),
                const SizedBox(height: 14),
                FilterChipGroup<String>(
                  label: 'Status',
                  options: const [MapEntry('Active', 'active'), MapEntry('Pending activation', 'pending_approval')],
                  selected: _statusFilter,
                  onChanged: (v) => setState(() => _statusFilter = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search name or email',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: AppColors.panel,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.line)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('${results.length} of ${_users.length} users', style: AppTextStyles.bodySoft),
                const SizedBox(height: 10),

                if (results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: Text('No users match these filters.', style: AppTextStyles.bodySoft)),
                  )
                else
                  ...results.map((u) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18, backgroundColor: AppColors.primarySoft,
                                    child: Text(u.fullName.isNotEmpty ? u.fullName[0] : '?',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(u.fullName, style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 12.5)),
                                        Text('${u.role.name} · ${_groupName(u.groupId)}', style: AppTextStyles.bodySoft),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: u.status == 'active' ? AppColors.presentBg : AppColors.lateBg,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(u.status, style: TextStyle(
                                      fontSize: 9, fontWeight: FontWeight.w700,
                                      color: u.status == 'active' ? AppColors.present : AppColors.late,
                                    )),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: [
                                  if (u.status != 'active')
                                    TextButton(onPressed: () => _activate(u), child: const Text('Activate')),
                                  if (u.status == 'active')
                                    TextButton(onPressed: () => _deactivate(u), child: const Text('Deactivate')),
                                  TextButton(onPressed: () => _assignGroup(u), child: const Text('Team')),
                                  TextButton(onPressed: () => _assignRole(u), child: const Text('Role')),
                                  TextButton(onPressed: () => _deleteUser(u), child: const Text('Delete', style: TextStyle(color: AppColors.absent))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}