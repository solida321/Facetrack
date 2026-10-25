import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/user_api.dart';
import '../../../core/network/group_api.dart';
import '../../../core/network/role_api.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/role_model.dart';
import '../groups/group_management_screen.dart';

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

  // The filters. The list on screen = users that pass all of them.
  final _searchController = TextEditingController();
  String _statusFilter = 'all'; // all | active | pending_approval | inactive
  int? _roleFilter; // role id, null = every role
  int? _teamFilter; // team (group) id, null = every team

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final users = await UserApi.getAll();
      final groups = await GroupApi.getAll();
      final roles = await RoleApi.getAll();
      setState(() {
        _users = users;
        _groups = groups;
        _roles = roles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
            child: Row(
              children: [
                if (isCurrent)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                if (isCurrent) const SizedBox(width: 8),
                Text(
                  g.name,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
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
            child: Row(
              children: [
                if (isCurrent)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                if (isCurrent) const SizedBox(width: 8),
                Text(
                  r.name,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
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
        content: Text(
          'This permanently deletes ${user.fullName}. If they have attendance history, this may fail — consider Deactivate instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.absent),
            ),
          ),
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
            const SnackBar(
              content: Text(
                'Could not delete — this user has attendance history. Try Deactivate instead.',
              ),
            ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create user', style: AppTextStyles.heading),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: roleId,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: _roles
                      .map(
                        (r) =>
                            DropdownMenuItem(value: r.id, child: Text(r.name)),
                      )
                      .toList(),
                  onChanged: (v) => setSheetState(() => roleId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: groupId,
                  decoration: const InputDecoration(
                    labelText: 'Team (optional)',
                  ),
                  items: _groups
                      .map(
                        (g) =>
                            DropdownMenuItem(value: g.id, child: Text(g.name)),
                      )
                      .toList(),
                  onChanged: (v) => setSheetState(() => groupId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: createStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'pending_approval',
                      child: Text('Pending approval'),
                    ),
                  ],
                  onChanged: (v) =>
                      setSheetState(() => createStatus = v ?? 'active'),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
    return match.isNotEmpty ? match.first.name : 'No team';
  }

  // ---------- filters ----------

  List<UserModel> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _users.where((u) {
      if (_statusFilter != 'all' && u.status != _statusFilter) return false;
      if (_roleFilter != null && u.role.id != _roleFilter) return false;
      if (_teamFilter != null && u.groupId != _teamFilter) return false;
      if (query.isNotEmpty) {
        final text = '${u.fullName} ${u.email} ${u.role.name} ${_groupName(u.groupId)}'
            .toLowerCase();
        if (!text.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  bool get _hasActiveFilter =>
      _statusFilter != 'all' ||
      _roleFilter != null ||
      _teamFilter != null ||
      _searchController.text.trim().isNotEmpty;

  void _clearFilters() {
    setState(() {
      _statusFilter = 'all';
      _roleFilter = null;
      _teamFilter = null;
      _searchController.clear();
    });
  }

  int _countStatus(String status) => _users.where((u) => u.status == status).length;

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primarySoft,
        backgroundColor: AppColors.panel,
        side: const BorderSide(color: AppColors.line),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.primary : AppColors.inkSoft,
        ),
      ),
    );
  }

  Widget _filters() {
    final teamName = _teamFilter == null ? 'All teams' : _groupName(_teamFilter);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by name, email, role or team',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _searchController.clear()),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          // Status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(
                  label: 'All ${_users.length}',
                  selected: _statusFilter == 'all',
                  onTap: () => setState(() => _statusFilter = 'all'),
                ),
                _chip(
                  label: 'Active ${_countStatus('active')}',
                  selected: _statusFilter == 'active',
                  onTap: () => setState(() => _statusFilter = 'active'),
                ),
                _chip(
                  label: 'Pending ${_countStatus('pending_approval')}',
                  selected: _statusFilter == 'pending_approval',
                  onTap: () => setState(() => _statusFilter = 'pending_approval'),
                ),
                _chip(
                  label: 'Inactive ${_countStatus('inactive')}',
                  selected: _statusFilter == 'inactive',
                  onTap: () => setState(() => _statusFilter = 'inactive'),
                ),
              ],
            ),
          ),
          // Role
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(
                  label: 'Any role',
                  selected: _roleFilter == null,
                  onTap: () => setState(() => _roleFilter = null),
                ),
                for (final r in _roles)
                  _chip(
                    label: r.name,
                    selected: _roleFilter == r.id,
                    onTap: () => setState(() => _roleFilter = r.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Team: tap to pick one from a menu
              PopupMenuButton<int>(
                tooltip: 'Filter by team',
                onSelected: (id) => setState(() => _teamFilter = id == -1 ? null : id),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: -1, child: Text('All teams')),
                  for (final g in _groups)
                    PopupMenuItem(value: g.id, child: Text(g.name)),
                ],
                child: IgnorePointer(
                  child: InputChip(
                    avatar: const Icon(Icons.groups_outlined, size: 16, color: AppColors.primary),
                    label: Text(teamName),
                    onPressed: () {},
                    backgroundColor: _teamFilter == null ? AppColors.panel : AppColors.primarySoft,
                    side: const BorderSide(color: AppColors.line),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Spacer(),
              if (_hasActiveFilter)
                TextButton(onPressed: _clearFilters, child: const Text('Clear filters')),
            ],
          ),
        ],
      ),
    );
  }

  // A scrollable message, so pull-to-refresh also works on an empty list.
  Widget _scrollableMessage(String text) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(child: Text(text, style: AppTextStyles.bodySoft)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _isLoading ? <UserModel>[] : _filtered;

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
            Text('People, in one place.', style: AppTextStyles.headline),
            Text(
              'Every user across all teams',
              style: AppTextStyles.bodySoft,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Teams',
            icon: const Icon(Icons.groups_outlined, color: AppColors.primary),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GroupManagementScreen()),
              );
              if (mounted) _load(); // pick up teams added, renamed or removed there
            },
          ),
          IconButton(
            tooltip: 'Add user',
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: _openCreateForm,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                _filters(),
                if (_users.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Showing ${shown.length} of ${_users.length}',
                        style: AppTextStyles.label,
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: _users.isEmpty
                        ? _scrollableMessage('No users yet.')
                        : shown.isEmpty
                            ? _scrollableMessage('No users match your filters.')
                            : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: shown.length,
              itemBuilder: (context, i) {
                final u = shown[i];
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
                                u.fullName.isNotEmpty ? u.fullName[0] : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u.fullName,
                                    style: const TextStyle(
                                      fontFamily: 'Sora',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  Text(
                                    '${u.role.name} · ${_groupName(u.groupId)}',
                                    style: AppTextStyles.bodySoft,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: u.status == 'active'
                                    ? AppColors.presentBg
                                    : AppColors.lateBg,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                u.status,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: u.status == 'active'
                                      ? AppColors.present
                                      : AppColors.late,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (u.status != 'active')
                              TextButton(
                                onPressed: () => _activate(u),
                                child: const Text('Activate'),
                              ),
                            if (u.status == 'active')
                              TextButton(
                                onPressed: () => _deactivate(u),
                                child: const Text('Deactivate'),
                              ),
                            TextButton(
                              onPressed: () => _assignGroup(u),
                              child: const Text('Team'),
                            ),
                            TextButton(
                              onPressed: () => _assignRole(u),
                              child: const Text('Role'),
                            ),
                            TextButton(
                              onPressed: () => _deleteUser(u),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: AppColors.absent),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
                  ),
                ),
              ],
            ),
    );
  }
}