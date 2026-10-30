import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/group_api.dart';
import '../../../core/network/user_api.dart';
import '../../../data/models/group_model.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/bloom_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/primary_button.dart';
import 'team_members_screen.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  List<GroupModel> _groups = [];
  Map<int, int> _memberCount = {}; // team id -> number of people
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final groups = await GroupApi.getAll();
      final users = await UserApi.getAll();
      final counts = <int, int>{};
      for (final u in users) {
        if (u.groupId != null) counts[u.groupId!] = (counts[u.groupId!] ?? 0) + 1;
      }
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _memberCount = counts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openTeam(GroupModel g) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TeamMembersScreen(group: g)));
    if (mounted) _load(); // member counts may have changed
  }

  Future<void> _delete(int groupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete team?'),
        content: const Text(
          'People and schedules that still belong to this team must be moved first. The app will tell you if the team is still in use.',
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
    if (confirm == true) {
      try {
        await GroupApi.delete(groupId);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(apiErrorMessage(e, fallback: 'Could not delete this team.'))),
          );
        }
      }
    }
  }

  Future<void> _openForm({GroupModel? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing != null ? 'Edit team' : 'New team', style: AppTextStyles.heading),
              const SizedBox(height: 16),
              AppTextField(label: 'Name', controller: nameController),
              const SizedBox(height: 16),
              PrimaryButton(
                  label: 'Save',
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final group = GroupModel(
                      id: existing?.id ?? 0,
                      name: nameController.text.trim(),
                      type: 'team', // one concept only: every group is a team
                      ownerUserId: existing?.ownerUserId,
                    );
                    if (existing != null) {
                      await GroupApi.update(existing.id, group);
                    } else {
                      await GroupApi.create(group);
                    }
                    _load();
                    if (context.mounted) Navigator.pop(context);
                  },
              ),
            ],
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
            Text('Teams', style: AppTextStyles.headline),
            Text(
              _groups.length == 1 ? '1 team · tap a team to see its people' : '${_groups.length} teams · tap a team to see its people',
              style: AppTextStyles.bodySoft,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'New team',
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                onPressed: () => _openForm(),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _groups.isEmpty
              ? const EmptyState(
                  message: 'No teams yet. Tap + to create one.',
                  icon: Icons.groups_2_outlined,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _groups.length,
                    itemBuilder: (context, i) {
                      final g = _groups[i];
                      final count = _memberCount[g.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BloomCard(
                          onTap: () => _openTeam(g),
                          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.groups_rounded,
                                    color: AppColors.primaryDeep, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      g.name,
                                      style: const TextStyle(
                                        fontFamily: 'Sora',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(count == 1 ? '1 person' : '$count people', style: AppTextStyles.bodySoft),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit team',
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _openForm(existing: g),
                              ),
                              IconButton(
                                tooltip: 'Delete team',
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.absent),
                                onPressed: () => _delete(g.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}