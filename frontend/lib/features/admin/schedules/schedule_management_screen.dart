import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/schedule_api.dart';
import '../../../core/network/group_api.dart';
import '../../../core/network/location_api.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/location_model.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  List<ScheduleModel> _schedules = [];
  List<GroupModel> _groups = [];
  List<LocationModel> _locations = [];
  bool _isLoading = true;

  String _dayName(int? dayOfWeek) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (dayOfWeek == null || dayOfWeek < 0 || dayOfWeek > 6) return '';
    return days[dayOfWeek];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final schedules = await ScheduleApi.getAll();
      final groups = await GroupApi.getAll();
      final locations = await LocationApi.getAll();
      setState(() {
        _schedules = schedules;
        _groups = groups;
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _groupName(int groupId) {
    final match = _groups.where((g) => g.id == groupId).toList();
    return match.isNotEmpty ? match.first.name : 'Unknown';
  }

  List<List<ScheduleModel>> _groupedSchedules() {
    final Map<String, List<ScheduleModel>> groups = {};
    for (final s in _schedules) {
      final key = '${s.sessionName}|${s.groupId}|${s.startTime}|${s.endTime}|${s.locationId}';
      groups.putIfAbsent(key, () => []).add(s);
    }
    final result = groups.values.toList();
    for (final group in result) {
      group.sort((a, b) => (a.dayOfWeek ?? 0).compareTo(b.dayOfWeek ?? 0));
    }
    return result;
  }

  Future<void> _deleteGroup(List<ScheduleModel> group) async {
    final dayLabels = group.map((s) => _dayName(s.dayOfWeek)).join(', ');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete schedule?'),
        content: Text('This removes all days ($dayLabels) for this schedule.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.absent))),
        ],
      ),
    );
    if (confirm == true) {
      for (final s in group) {
        await ScheduleApi.delete(s.id);
      }
      _load();
    }
  }

  Future<void> _openForm({ScheduleModel? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ScheduleFormSheet(
        existing: existing,
        groups: _groups,
        locations: _locations,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedSchedules();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Schedules', style: AppTextStyles.heading),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: () => _openForm()),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : grouped.isEmpty
              ? Center(child: Text('No schedules yet.', style: AppTextStyles.bodySoft))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: grouped.length,
                  itemBuilder: (context, i) {
                    final group = grouped[i];
                    final first = group.first;
                    final dayLabels = group.map((s) => _dayName(s.dayOfWeek)).join(', ');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(first.sessionName, style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('$dayLabels · ${first.startTime.substring(0, 5)} – ${first.endTime.substring(0, 5)} · ${_groupName(first.groupId)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _openForm(existing: first),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.absent),
                              onPressed: () => _deleteGroup(group),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _ScheduleFormSheet extends StatefulWidget {
  final ScheduleModel? existing;
  final List<GroupModel> groups;
  final List<LocationModel> locations;
  final VoidCallback onSaved;

  const _ScheduleFormSheet({this.existing, required this.groups, required this.locations, required this.onSaved});

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  final _nameController = TextEditingController();
  int? _groupId;
  int? _locationId;
  final Set<int> _selectedDays = {0};
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  final _graceController = TextEditingController(text: '10');
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.sessionName;
      _groupId = e.groupId;
      _locationId = e.locationId;
      _selectedDays
        ..clear()
        ..add(e.dayOfWeek ?? 0);
      _graceController.text = '${e.gracePeriodMinutes}';
      final startParts = e.startTime.split(':');
      _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      final endParts = e.endTime.split(':');
      _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
    }
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _save() async {
    if (_groupId == null || _nameController.text.trim().isEmpty || _selectedDays.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      if (widget.existing != null) {
        final schedule = ScheduleModel(
          id: widget.existing!.id,
          groupId: _groupId!,
          sessionName: _nameController.text.trim(),
          dayOfWeek: _selectedDays.first,
          specificDate: null,
          startTime: _fmt(_startTime),
          endTime: _fmt(_endTime),
          gracePeriodMinutes: int.tryParse(_graceController.text) ?? 10,
          locationId: _locationId,
        );
        await ScheduleApi.update(widget.existing!.id, schedule);
      } else {
        for (final day in _selectedDays) {
          final schedule = ScheduleModel(
            id: 0,
            groupId: _groupId!,
            sessionName: _nameController.text.trim(),
            dayOfWeek: day,
            specificDate: null,
            startTime: _fmt(_startTime),
            endTime: _fmt(_endTime),
            gracePeriodMinutes: int.tryParse(_graceController.text) ?? 10,
            locationId: _locationId,
          );
          await ScheduleApi.create(schedule);
        }
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing != null ? 'Edit schedule' : 'New schedule', style: AppTextStyles.heading),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Session name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _groupId,
              decoration: const InputDecoration(labelText: 'Group'),
              items: widget.groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
              onChanged: (v) => setState(() => _groupId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _locationId,
              decoration: const InputDecoration(labelText: 'Location (optional)'),
              items: widget.locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
              onChanged: (v) => setState(() => _locationId = v),
            ),
            const SizedBox(height: 12),
            Text('Days', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final selected = _selectedDays.contains(i);
                return FilterChip(
                  label: Text(_days[i]),
                  selected: selected,
                  onSelected: widget.existing != null
                      ? null
                      : (val) {
                          setState(() {
                            if (val) {
                              _selectedDays.add(i);
                            } else {
                              _selectedDays.remove(i);
                            }
                          });
                        },
                  selectedColor: AppColors.primarySoft,
                  checkmarkColor: AppColors.primary,
                );
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start'),
                    subtitle: Text(_startTime.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _startTime);
                      if (picked != null) setState(() => _startTime = picked);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End'),
                    subtitle: Text(_endTime.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _endTime);
                      if (picked != null) setState(() => _endTime = picked);
                    },
                  ),
                ),
              ],
            ),
            TextField(
              controller: _graceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Grace period (minutes)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _isSaving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}