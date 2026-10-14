import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/schedule_api.dart';
import '../../../core/network/group_api.dart';
import '../../../core/network/location_api.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/location_model.dart';
import '../../../widgets/filter_chip_group.dart';

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

  int? _teamFilter;
  int? _dayFilter;

  String _dayName(int? d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (d == null || d < 0 || d > 6) return '';
    return days[d];
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

  // Rows that share name + team + time + location are shown as one card.
  List<List<ScheduleModel>> _groupedSchedules() {
    final Map<String, List<ScheduleModel>> groups = {};
    for (final s in _schedules.where((s) => s.dayOfWeek != null)) {
      final key = '${s.sessionName}|${s.groupId}|${s.startTime}|${s.endTime}|${s.locationId}';
      groups.putIfAbsent(key, () => []).add(s);
    }
    final result = groups.values.toList();
    for (final g in result) {
      g.sort((a, b) => a.dayOfWeek!.compareTo(b.dayOfWeek!));
    }
    return result;
  }

  List<List<ScheduleModel>> get _filteredGroups {
    return _groupedSchedules().where((group) {
      final first = group.first;
      if (_teamFilter != null && first.groupId != _teamFilter) return false;
      if (_dayFilter != null && !group.any((s) => s.dayOfWeek == _dayFilter)) return false;
      return true;
    }).toList();
  }

  Future<void> _deleteGroup(List<ScheduleModel> group) async {
    final dayLabels = group.map((s) => _dayName(s.dayOfWeek)).join(', ');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete schedule?'),
        content: Text('This removes all days ($dayLabels). Past attendance records are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.absent))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      for (final s in group) {
        await ScheduleApi.delete(s.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete this schedule. Please try again.')),
        );
      }
    }
    _load();
  }

  Future<void> _openForm({List<ScheduleModel>? existingGroup}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ScheduleFormSheet(
        existingGroup: existingGroup,
        groups: _groups,
        locations: _locations,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _filteredGroups;

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
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                FilterChipGroup<int>(
                  label: 'Team',
                  options: _groups.map((g) => MapEntry(g.name, g.id)).toList(),
                  selected: _teamFilter,
                  onChanged: (v) => setState(() => _teamFilter = v),
                ),
                const SizedBox(height: 14),
                FilterChipGroup<int>(
                  label: 'Day',
                  options: const [
                    MapEntry('Mon', 0), MapEntry('Tue', 1), MapEntry('Wed', 2),
                    MapEntry('Thu', 3), MapEntry('Fri', 4), MapEntry('Sat', 5), MapEntry('Sun', 6),
                  ],
                  selected: _dayFilter,
                  onChanged: (v) => setState(() => _dayFilter = v),
                ),
                const SizedBox(height: 16),
                if (grouped.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: Text('No schedules match these filters.', style: AppTextStyles.bodySoft)),
                  )
                else
                  ...grouped.map((group) {
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
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _openForm(existingGroup: group)),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.absent), onPressed: () => _deleteGroup(group)),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _ScheduleFormSheet extends StatefulWidget {
  final List<ScheduleModel>? existingGroup; // null = creating new
  final List<GroupModel> groups;
  final List<LocationModel> locations;
  final VoidCallback onSaved;

  const _ScheduleFormSheet({this.existingGroup, required this.groups, required this.locations, required this.onSaved});

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

  bool get _isEditing => widget.existingGroup != null;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final group = widget.existingGroup;
    if (group != null && group.isNotEmpty) {
      final first = group.first;
      _nameController.text = first.sessionName;
      _groupId = first.groupId;
      _locationId = first.locationId;
      _graceController.text = '${first.gracePeriodMinutes}';
      _selectedDays
        ..clear()
        ..addAll(group.map((s) => s.dayOfWeek!));
      final sp = first.startTime.split(':');
      _startTime = TimeOfDay(hour: int.parse(sp[0]), minute: int.parse(sp[1]));
      final ep = first.endTime.split(':');
      _endTime = TimeOfDay(hour: int.parse(ep[0]), minute: int.parse(ep[1]));
    }
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  ScheduleModel _build(int day, {int id = 0}) => ScheduleModel(
        id: id,
        groupId: _groupId!,
        sessionName: _nameController.text.trim(),
        dayOfWeek: day,
        specificDate: null,
        startTime: _fmt(_startTime),
        endTime: _fmt(_endTime),
        gracePeriodMinutes: int.tryParse(_graceController.text) ?? 10,
        locationId: _locationId,
      );

  Future<void> _save() async {
    if (_groupId == null || _nameController.text.trim().isEmpty || _selectedDays.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      // Existing rows keyed by weekday, so we know which days to update,
      // which to add, and which to remove.
      final existingByDay = {for (final s in widget.existingGroup ?? <ScheduleModel>[]) s.dayOfWeek!: s};

      for (final day in _selectedDays) {
        final row = existingByDay[day];
        if (row != null) {
          await ScheduleApi.update(row.id, _build(day, id: row.id)); // keep + update
        } else {
          await ScheduleApi.create(_build(day)); // newly ticked day
        }
      }
      for (final entry in existingByDay.entries) {
        if (!_selectedDays.contains(entry.key)) {
          await ScheduleApi.delete(entry.value.id); // day was unticked
        }
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the schedule. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEditing ? 'Edit schedule' : 'New schedule', style: AppTextStyles.heading),
            if (_isEditing) ...[
              const SizedBox(height: 4),
              Text('Changes apply to every day in this schedule.', style: AppTextStyles.bodySoft),
            ],
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Session name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _groupId,
              decoration: const InputDecoration(labelText: 'Team'),
              items: widget.groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
              onChanged: _isEditing ? null : (v) => setState(() => _groupId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _locationId,
              decoration: const InputDecoration(labelText: 'Location'),
              items: widget.locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
              onChanged: (v) => setState(() => _locationId = v),
            ),
            const SizedBox(height: 12),
            Text('Days', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                return FilterChip(
                  label: Text(_days[i]),
                  selected: _selectedDays.contains(i),
                  onSelected: (val) => setState(() {
                    if (val) {
                      _selectedDays.add(i);
                    } else {
                      _selectedDays.remove(i);
                    }
                  }),
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