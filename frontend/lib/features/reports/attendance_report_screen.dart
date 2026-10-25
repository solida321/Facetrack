import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/network/api_error.dart';
import '../../core/network/attendance_api.dart';
import '../../core/network/group_api.dart';
import '../../core/network/user_api.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/attendance_record_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/user_model.dart';
import '../../widgets/status_pill.dart';

/// Small button for the manager and admin home screens.
class AttendanceReportButton extends StatelessWidget {
  const AttendanceReportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AttendanceReportScreen()),
        ),
        icon: const Icon(Icons.assessment_outlined, size: 18, color: AppColors.primary),
        label: const Text(
          'Attendance report',
          style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      ),
    );
  }
}

/// Who came, when they left, and who left early or forgot to check out.
/// The server already limits the list: admin sees everyone, manager only the own team.
class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  List<AttendanceRecordModel> _records = [];
  Map<int, UserModel> _users = {};
  List<GroupModel> _groups = [];
  bool _isLoading = true;
  bool _isExporting = false;

  late DateTimeRange _range;
  String _statusFilter = 'all'; // all, present, late, absent, early_leave, missing
  int? _groupFilter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month, now.day));
    _load();
  }

  Future<void> _load() async {
    try {
      final records = await AttendanceApi.getAll();
      final users = await UserApi.getAll();
      List<GroupModel> groups = [];
      try {
        groups = await GroupApi.getAll();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _records = records;
        _users = {for (final u in users) u.id: u};
        _groups = groups;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _sameOrBetween(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return !day.isBefore(_range.start) && !day.isAfter(_range.end);
  }

  List<AttendanceRecordModel> get _filtered {
    final list = _records.where((r) {
      if (!_sameOrBetween(r.attendanceDate)) return false;
      if (_groupFilter != null && _users[r.userId]?.groupId != _groupFilter) return false;
      switch (_statusFilter) {
        case 'early_leave':
          return r.leftEarly;
        case 'missing':
          return r.missingCheckout;
        case 'all':
          return true;
        default:
          return r.status == _statusFilter;
      }
    }).toList();
    list.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));
    return list;
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

  /// Copies the CSV text. Paste it into Excel or Google Sheets.
  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      final csv = await AttendanceApi.exportCsv(from: _range.start, to: _range.end, groupId: _groupFilter);
      await Clipboard.setData(ClipboardData(text: csv));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report copied. Paste it into Excel or Google Sheets.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e, fallback: 'Could not export the report.'))),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _day(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Widget _chip(String value, String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _statusFilter == value,
          onSelected: (_) => setState(() => _statusFilter = value),
          selectedColor: AppColors.primarySoft,
          backgroundColor: AppColors.panel,
        ),
      );

  Widget _row(AttendanceRecordModel r) {
    final name = _users[r.userId]?.fullName ?? 'User #${r.userId}';
    final inText = r.checkInTime == null ? 'No check-in' : 'In ${DateFormatter.time(r.checkInTime!)}';
    final outText = r.missingCheckout
        ? 'Out —'
        : r.checkOutTime == null
            ? 'Not checked out'
            : 'Out ${DateFormatter.time(r.checkOutTime!)}';

    StatusPill pill;
    switch (r.status) {
      case 'present':
        pill = StatusPill.present('Present');
        break;
      case 'late':
        pill = StatusPill.late('Late');
        break;
      case 'absent':
        pill = StatusPill.absent('Absent');
        break;
      default:
        pill = StatusPill.neutral(r.status ?? '—');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('${_day(r.attendanceDate)} · $inText · $outText', style: AppTextStyles.bodySoft),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                pill,
                if (r.leftEarly) ...[const SizedBox(height: 4), StatusPill.late('Early leave')],
                if (r.missingCheckout) ...[const SizedBox(height: 4), StatusPill.absent('Missing check-out')],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final early = items.where((r) => r.leftEarly).length;
    final missing = items.where((r) => r.missingCheckout).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Attendance report', style: AppTextStyles.heading),
        actions: [
          IconButton(
            tooltip: 'Copy report (CSV)',
            onPressed: _isExporting ? null : _export,
            icon: _isExporting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_download_outlined, color: AppColors.primary),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickRange,
                          icon: const Icon(Icons.date_range_rounded, size: 18),
                          label: Text('${_day(_range.start)} – ${_day(_range.end)}'),
                        ),
                      ),
                      if (_groups.length > 1) ...[
                        const SizedBox(width: 8),
                        DropdownButton<int?>(
                          value: _groupFilter,
                          hint: const Text('All teams'),
                          underline: const SizedBox.shrink(),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('All teams')),
                            for (final g in _groups) DropdownMenuItem<int?>(value: g.id, child: Text(g.name)),
                          ],
                          onChanged: (v) => setState(() => _groupFilter = v),
                        ),
                      ],
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                  child: Row(
                    children: [
                      _chip('all', 'All'),
                      _chip('present', 'Present'),
                      _chip('late', 'Late'),
                      _chip('absent', 'Absent'),
                      _chip('early_leave', 'Early leave'),
                      _chip('missing', 'Missing check-out'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${items.length} records · $early early leave · $missing missing check-out',
                      style: AppTextStyles.bodySoft,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 100),
                              Center(child: Text('No records for this filter.', style: AppTextStyles.bodySoft)),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: items.length,
                            itemBuilder: (_, i) => _row(items[i]),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}