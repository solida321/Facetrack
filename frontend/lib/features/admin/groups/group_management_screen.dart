import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/group_api.dart';
import '../../../data/models/group_model.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  List<GroupModel> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final groups = await GroupApi.getAll();
      setState(() { _groups = groups; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(GroupModel group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${group.name}?'),
        content: const Text('Move its members to another team first. A team that still has members or schedule history cannot be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.absent))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await GroupApi.delete(group.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot delete this team — it still has members or schedule history.')),
        );
      }
    }
  }

  Future<void> _openForm({GroupModel? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(existing != null ? 'Edit team' : 'New team', style: AppTextStyles.heading),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Team name')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  final group = GroupModel(
                    id: existing?.id ?? 0,
                    name: nameController.text.trim(),
                    type: existing?.type ?? 'team',
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Save'),
              ),
            ),
          ],
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
        title: Text('Teams', style: AppTextStyles.heading),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: () => _openForm()),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _groups.isEmpty
              ? Center(child: Text('No teams yet.', style: AppTextStyles.bodySoft))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _groups.length,
                  itemBuilder: (context, i) {
                    final g = _groups[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(g.name, style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _openForm(existing: g)),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.absent), onPressed: () => _delete(g)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}