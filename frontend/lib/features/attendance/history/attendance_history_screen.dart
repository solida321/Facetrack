import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/network/schedule_api.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../widgets/status_pill.dart';
import 'attendance_detail_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  List<AttendanceRecordModel> _records = [];
  Map<int, String> _sessionNames = {}; // schedule id -> "Morning Shift"
  bool _isLoading = true;

  // The three filters. The list on screen = all records that pass all three.
  String _statusFilter = 'all'; // all | present | late | absent
  DateTimeRange? _range;
  final _searchController = TextEditingController();

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
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final records = await AttendanceApi.getMyHistory(user.id);
      records.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate)); // newest first

      // Shift names make the list readable and searchable. Optional: if this
      // fails we simply show "Shift".
      var names = <int, String>{};
      final groupId = user.groupId;
      if (groupId != null) {
        try {
          final schedules = await ScheduleApi.getByGroup(groupId);
          names = {for (final s in schedules) s.id: s.sessionName};
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _records = records;
        _sessionNames = names;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _sessionName(AttendanceRecordModel r) => _sessionNames[r.scheduleId] ?? 'Shift';

  String _dateText(DateTime d) => DateFormatter.date(d);

  /// Everything a person might type to find a record, as one lowercase string.
  String _searchText(AttendanceRecordModel r) {
    final d = r.attendanceDate;
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '${_weekdays[d.weekday - 1]} ${_months[d.month - 1]} $dd/$mm/${d.year} '
            '${_dateText(d)} ${_sessionName(r)} ${r.status ?? ''}'
        .toLowerCase();
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<AttendanceRecordModel> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final range = _range; // local copy so Dart knows it is not null below
    final start = range == null ? null : _dayOnly(range.start);
    final end = range == null ? null : _dayOnly(range.end);

    return _records.where((r) {
      if (_statusFilter != 'all' && (r.status ?? '') != _statusFilter) return false;

      if (start != null && end != null) {
        final day = _dayOnly(r.attendanceDate);
        if (day.isBefore(start) || day.isAfter(end)) return false;
      }

      if (query.isNotEmpty && !_searchText(r).contains(query)) return false;
      return true;
    }).toList();
  }

  bool get _hasActiveFilter =>
      _statusFilter != 'all' || _range != null || _searchController.text.trim().isNotEmpty;

  void _clearFilters() {
    setState(() {
      _statusFilter = 'all';
      _range = null;
      _searchController.clear();
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  String _rangeLabel(DateTimeRange r) =>
      '${_dateText(r.start)} – ${_dateText(r.end)}';

  int _count(String status) => _records.where((r) => r.status == status).length;

  StatusPill _pill(String? status) {
    switch (status) {
      case 'present':
        return StatusPill.present('Present');
      case 'late':
        return StatusPill.late('Late');
      case 'absent':
        return StatusPill.absent('Absent');
      default:
        return StatusPill.neutral(status ?? '—');
    }
  }

  String _subtitle(AttendanceRecordModel r) {
    final checkIn = r.checkInTime;
    final checkOut = r.checkOutTime;
    if (checkIn == null) return 'No check-in';
    final inText = 'In ${DateFormatter.time(checkIn)}';
    final outText = r.missingCheckout
        ? 'missing check-out'
        : checkOut == null
            ? 'not checked out'
            : 'Out ${DateFormatter.time(checkOut)}${r.leftEarly ? ' (left early)' : ''}';
    return '$inText · $outText';
  }

  Widget _statusChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _statusFilter == value,
        onSelected: (_) => setState(() => _statusFilter = value),
        selectedColor: AppColors.primarySoft,
        backgroundColor: AppColors.panel,
        side: const BorderSide(color: AppColors.line),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _statusFilter == value ? AppColors.primary : AppColors.inkSoft,
        ),
      ),
    );
  }

  Widget _filters() {
    final range = _range;
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
              hintText: 'Search by date, shift or status',
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusChip('all', 'All ${_records.length}'),
                _statusChip('present', 'Present ${_count('present')}'),
                _statusChip('late', 'Late ${_count('late')}'),
                _statusChip('absent', 'Absent ${_count('absent')}'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              InputChip(
                avatar: const Icon(Icons.date_range_rounded, size: 16, color: AppColors.primary),
                label: Text(range == null ? 'Any date' : _rangeLabel(range)),
                onPressed: _pickRange,
                onDeleted: range == null ? null : () => setState(() => _range = null),
                backgroundColor: range == null ? AppColors.panel : AppColors.primarySoft,
                side: const BorderSide(color: AppColors.line),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

  Widget _list(List<AttendanceRecordModel> shown) {
    if (_records.isEmpty) {
      return _scrollableMessage('No attendance records yet.');
    }
    if (shown.isEmpty) {
      return _scrollableMessage('No records match your filters.');
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: shown.length,
      separatorBuilder: (context, index) => const Divider(color: AppColors.line, height: 1),
      itemBuilder: (context, i) {
        final r = shown[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AttendanceDetailScreen(record: r)),
            );
          },
          title: Text(
            '${_dateText(r.attendanceDate)} · ${_sessionName(r)}',
            style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 13),
          ),
          subtitle: Text(_subtitle(r), style: AppTextStyles.bodySoft),
          trailing: _pill(r.status),
        );
      },
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
    final shown = _isLoading ? <AttendanceRecordModel>[] : _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('History', style: AppTextStyles.heading),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _filters(),
                if (_records.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Showing ${shown.length} of ${_records.length}',
                        style: AppTextStyles.label,
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: _list(shown),
                  ),
                ),
              ],
            ),
    );
  }
}