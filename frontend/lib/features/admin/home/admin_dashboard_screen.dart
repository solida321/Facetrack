import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/network/correction_api.dart';
import '../../../core/network/group_api.dart';
import '../../../core/network/leave_api.dart';
import '../../../core/network/schedule_api.dart';
import '../../../core/network/user_api.dart';
import '../../../core/services/attendance_csv_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/attendance_row.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/models/user_model.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/bloom_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/filter_chips.dart';
import '../../../widgets/outline_button.dart';
import '../../../widgets/stat_card.dart';
import '../../../widgets/status_pill.dart';
import '../../notifications/notification_bell.dart';
import 'package:flutter/rendering.dart';



class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<AttendanceRecordModel> _records = [];
  List<UserModel> _users = [];
  List<GroupModel> _groups = [];
  int _pendingLeaves = 0;
  int _pendingCorrections = 0;
  int _onLeaveToday = 0;
  List<ScheduleModel> _schedules = [];
  bool _isLoading = true;

  // Period: 0 = 7 days, 1 = 30 days, 2 = custom range.
  int _preset = 0;
  late DateTime _from;
  late DateTime _to;

  // Filters for the attendance cards and the export.
  int _teamIndex = 0; // 0 = all teams, otherwise index + 1 in _groups
  int _statusIndex = 0;
  final _search = TextEditingController();
  int _shown = 20;
  bool _isExporting = false;

  static const _statusKeys = ['all', 'checked_in', 'present', 'late', 'absent', 'early_leave', 'missing'];

  final _scroll = ScrollController();
  final _detailsKey = GlobalKey();

  static const _absentBg = Color(0xFFF8E2DF);

  @override
  void initState() {
    super.initState();
    _applyPreset(7);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void _applyPreset(int days) {
    _to = _today;
    _from = _today.subtract(Duration(days: days - 1));
    _shown = 20;
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: _today,
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked != null) {
      setState(() {
        _preset = 2;
        _from = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _to = DateTime(picked.end.year, picked.end.month, picked.end.day);
        _shown = 20;
      });
    }
  }

  void _onPeriod(int i) {
    if (i == 2) {
      _pickRange();
      return;
    }
    setState(() {
      _preset = i;
      _applyPreset(i == 0 ? 7 : 30);
    });
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _load() async {
    try {
      try {
        await AttendanceApi.markAbsences(); // catch up on missed shifts
      } catch (_) {}
      final users = await UserApi.getAll();
      final records = await AttendanceApi.getAll();
      final groups = await GroupApi.getAll();
      List<ScheduleModel> schedules = [];
      try {
        schedules = await ScheduleApi.getAll();
      } catch (_) {}
      final leaves = await LeaveApi.getAllLeaves();
      final corrections = await CorrectionApi.getAllCorrections();
      if (!mounted) return;

      final t = DateTime.now();
      final today = DateTime(t.year, t.month, t.day);

      setState(() {
        _users = users;
        _records = records;
        _groups = groups;
        _schedules = schedules;
        _pendingLeaves = leaves.where((l) => l.status == 'pending').length;
        _pendingCorrections = corrections.where((c) => c.status == 'pending').length;
        _onLeaveToday = leaves.where((l) {
          final a = DateTime(l.dateFrom.year, l.dateFrom.month, l.dateFrom.day);
          final b = DateTime(l.dateTo.year, l.dateTo.month, l.dateTo.day);
          return l.status == 'approved' && !today.isBefore(a) && !today.isAfter(b);
        }).length;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _days => _to.difference(_from).inDays + 1;

  List<AttendanceRecordModel> get _inRange => _records.where((r) {
        final d = DateTime(r.attendanceDate.year, r.attendanceDate.month, r.attendanceDate.day);
        return !d.isBefore(_from) && !d.isAfter(_to);
      }).toList();

  /// Records in the period, after the team, status and search filters.
  List<AttendanceRow> _filteredRows(List<AttendanceRecordModel> range) {
    final rows = AttendanceRow.build(records: range, users: _users, groups: _groups, schedules: _schedules);
    final teamName = _teamIndex == 0 ? null : _groups[_teamIndex - 1].name;
    final status = _statusKeys[_statusIndex];
    final q = _search.text.trim().toLowerCase();

    final list = rows.where((r) {
      if (teamName != null && r.team != teamName) return false;
      switch (status) {
        case 'all':
          break;
        case 'checked_in':
          if (r.record.status != 'present' && r.record.status != 'late') return false;
          break;
        case 'early_leave':
          if (!r.record.leftEarly) return false;
          break;
        case 'missing':
          if (!r.record.missingCheckout) return false;
          break;
        default:
          if (r.record.status != status) return false;
      }
      if (q.isNotEmpty &&
          !r.name.toLowerCase().contains(q) &&
          !r.email.toLowerCase().contains(q) &&
          '${r.employeeId}' != q) {
        return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : a.name.compareTo(b.name);
    });
    return list;
  }

  /// A card on top was tapped: show today's records for that status in the
  /// details list below, and scroll down to it.
  void _showToday(String status) {
    setState(() {
      _preset = 2;
      _from = _today;
      _to = _today;
      _teamIndex = 0;
      _statusIndex = _statusKeys.indexOf(status);
      _search.clear();
      _shown = 20;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _detailsKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _export(List<AttendanceRow> rows) async {
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to export for this filter.')));
      return;
    }
    setState(() => _isExporting = true);
    try {
      await AttendanceCsvService.share(rows, from: _from, to: _to);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not export. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  int _count(List<AttendanceRecordModel> list, String status) => list.where((r) => r.status == status).length;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final range = _inRange;
    final rows = _filteredRows(range);
    final present = _count(range, 'present');
    final late = _count(range, 'late');
    final absent = _count(range, 'absent');

    final today = _records.where((r) => _sameDay(r.attendanceDate, now)).toList();
    final activeUsers = _users.where((u) => u.status == 'active').length;
    final pendingUsers = _users.where((u) => u.status == 'pending_approval').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView(
                  controller: _scroll,
                 scrollCacheExtent: const ScrollCacheExtent.pixels(6000), // keeps the details list built so the scroll can find it/ keeps the details list built so the scroll can find it
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dashboard', style: AppTextStyles.headline),
                              const SizedBox(height: 2),
                              Text('${now.day}/${now.month}/${now.year} · All teams', style: AppTextStyles.bodySoft),
                            ],
                          ),
                        ),
                        const NotificationBell(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const SizedBox(height: 18),

                    // ---- Today ----
                    Row(
                      children: [
                        Expanded(child: StatCard(value: '${today.where((r) => r.status == 'present' || r.status == 'late').length}', label: 'Checked in today', color: AppColors.present, background: AppColors.presentBg, onTap: () => _showToday('checked_in'))),
                        const SizedBox(width: 8),
                        Expanded(child: StatCard(value: '${_count(today, 'late')}', label: 'Late today', color: AppColors.late, background: AppColors.lateBg, onTap: () => _showToday('late'))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: StatCard(value: '${_count(today, 'absent')}', label: 'Absent today', color: AppColors.absent, background: _absentBg, onTap: () => _showToday('absent'))),
                        const SizedBox(width: 8),
                        Expanded(child: StatCard(value: '$_onLeaveToday', label: 'On leave', color: AppColors.primary, background: AppColors.primarySoft)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: StatCard(value: '$activeUsers', label: 'Active users', color: AppColors.primary, background: AppColors.primarySoft)),
                        const SizedBox(width: 8),
                        Expanded(child: StatCard(value: '$pendingUsers', label: 'Awaiting activation', color: AppColors.late, background: AppColors.lateBg)),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ---- Period ----
                    AppFilterChips(
                      labels: const ['7 days', '30 days', 'Custom'],
                      selected: _preset,
                      onSelected: _onPeriod,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickRange,
                      child: Row(
                        children: [
                          const Icon(Icons.date_range_rounded, size: 16, color: AppColors.primaryDeep),
                          const SizedBox(width: 6),
                          Text('${DateFormatter.date(_from)} – ${DateFormatter.date(_to)}', style: AppTextStyles.bodySoft),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---- Pie ----
                    BloomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Attendance mix', style: AppTextStyles.subheading),
                          const SizedBox(height: 14),
                          if (present + late + absent == 0)
                            Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No records in this period.', style: AppTextStyles.bodySoft)))
                          else
                            Row(
                              children: [
                                SizedBox(
                                  width: 130,
                                  height: 130,
                                  child: PieChart(PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 28,
                                    sections: [
                                      if (present > 0) PieChartSectionData(value: present.toDouble(), color: AppColors.present, title: '$present', radius: 34, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                      if (late > 0) PieChartSectionData(value: late.toDouble(), color: AppColors.late, title: '$late', radius: 34, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                      if (absent > 0) PieChartSectionData(value: absent.toDouble(), color: AppColors.absent, title: '$absent', radius: 34, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                    ],
                                  )),
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _legend(AppColors.present, 'On time'),
                                    const SizedBox(height: 8),
                                    _legend(AppColors.late, 'Late'),
                                    const SizedBox(height: 8),
                                    _legend(AppColors.absent, 'Absent'),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---- Stacked bar by team ----
                    BloomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('By team', style: AppTextStyles.subheading),
                          const SizedBox(height: 14),
                          SizedBox(height: 180, child: _teamBarChart(range)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---- Line ----
                    BloomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check-ins per day', style: AppTextStyles.subheading),
                          const SizedBox(height: 14),
                          SizedBox(height: 160, child: _dailyLineChart(range)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    Text('Needs attention', style: AppTextStyles.subheading),
                    const SizedBox(height: 10),
                    _attentionRow('Leave requests waiting', _pendingLeaves),
                    _attentionRow('Correction requests waiting', _pendingCorrections),
                    _attentionRow('New accounts waiting for activation', pendingUsers),
                    const SizedBox(height: 22),

                    // ---- Attendance details + export ----
                    Row(
                      key: _detailsKey,
                      children: [
                        Expanded(child: Text('Attendance details', style: AppTextStyles.subheading)),
                        GestureDetector(
                          onTap: _isExporting ? null : () => _export(rows),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.primary, width: 1.5),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: _isExporting
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                : const Row(
                                    children: [
                                      Icon(Icons.download_rounded, size: 16, color: AppColors.primaryDeep),
                                      SizedBox(width: 6),
                                      Text('Export', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryDeep)),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Search',
                      controller: _search,
                      hint: 'Name, email or employee ID',
                      icon: Icons.search_rounded,
                      onChanged: (_) => setState(() => _shown = 20),
                    ),
                    const SizedBox(height: 12),
                    AppFilterChips(
                      labels: ['All teams', for (final g in _groups) g.name],
                      selected: _teamIndex,
                      onSelected: (i) => setState(() {
                        _teamIndex = i;
                        _shown = 20;
                      }),
                    ),
                    const SizedBox(height: 8),
                    AppFilterChips(
                      labels: const ['All', 'Checked in', 'Present', 'Late', 'Absent', 'Early leave', 'Missing check-out'],
                      selected: _statusIndex,
                      onSelected: (i) => setState(() {
                        _statusIndex = i;
                        _shown = 20;
                      }),
                    ),
                    const SizedBox(height: 10),
                    Text('${rows.length} records · Export saves all of them', style: AppTextStyles.bodySoft),
                    const SizedBox(height: 10),
                    if (rows.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: EmptyState(message: 'No records for this filter.', icon: Icons.assessment_outlined),
                      )
                    else ...[
                      for (final r in rows.take(_shown)) _rowCard(r),
                      if (rows.length > _shown)
                        AppOutlineButton(
                          label: 'Show more (${rows.length - _shown} left)',
                          onPressed: () => setState(() => _shown += 20),
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _teamBarChart(List<AttendanceRecordModel> range) {
    final userGroup = {for (final u in _users) u.id: u.groupId};
    final teams = _groups.where((g) => range.any((r) => userGroup[r.userId] == g.id)).toList();

    if (teams.isEmpty) {
      return Center(child: Text('No records in this period.', style: AppTextStyles.bodySoft));
    }

    int c(int teamId, String status) =>
        range.where((r) => userGroup[r.userId] == teamId && r.status == status).length;

    double maxY = 1;
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < teams.length; i++) {
      final p = c(teams[i].id, 'present').toDouble();
      final l = c(teams[i].id, 'late').toDouble();
      final a = c(teams[i].id, 'absent').toDouble();
      final total = p + l + a;
      if (total > maxY) maxY = total;
      groups.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: total,
          width: 22,
          borderRadius: BorderRadius.circular(4),
          rodStackItems: [
            BarChartRodStackItem(0, p, AppColors.present),
            BarChartRodStackItem(p, p + l, AppColors.late),
            BarChartRodStackItem(p + l, total, AppColors.absent),
          ],
        ),
      ]));
    }

    return BarChart(BarChartData(
      maxY: maxY + 1,
      barGroups: groups,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= teams.length) return const SizedBox.shrink();
              final name = teams[i].name;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(name.length > 9 ? '${name.substring(0, 8)}…' : name, style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
              );
            },
          ),
        ),
      ),
    ));
  }

  Widget _dailyLineChart(List<AttendanceRecordModel> range) {
    final start = _from;
    final spots = <FlSpot>[];
    double maxY = 1;

    for (var i = 0; i < _days; i++) {
      final day = start.add(Duration(days: i));
      final n = range.where((r) => _sameDay(r.attendanceDate, day) && (r.status == 'present' || r.status == 'late')).length.toDouble();
      if (n > maxY) maxY = n;
      spots.add(FlSpot(i.toDouble(), n));
    }

    return LineChart(LineChartData(
      minY: 0,
      maxY: maxY + 1,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _days <= 7 ? 1.0 : (_days / 6).ceilToDouble(),
            getTitlesWidget: (value, meta) {
              final day = start.add(Duration(days: value.toInt()));
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${day.day}/${day.month}', style: const TextStyle(fontSize: 9.5, color: AppColors.inkSoft)),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          dotData: FlDotData(show: _days <= 14),
          belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.08)),
        ),
      ],
    ));
  }

  Widget _rowCard(AttendanceRow r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BloomCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('ID ${r.employeeId} · ${r.email}', style: AppTextStyles.bodySoft, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(DateFormatter.date(r.date), style: AppTextStyles.label),
              ],
            ),
            const SizedBox(height: 8),
            Text('${r.team} · ${r.shift}', style: AppTextStyles.bodySoft),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _timeBlock('Check-in', r.checkIn, _inPill(r.checkInStatus))),
                Expanded(child: _timeBlock('Check-out', r.checkOut, _outPill(r.checkOutStatus))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBlock(String title, String time, Widget pill) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.label),
          const SizedBox(height: 2),
          Text(time, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          pill,
        ],
      );

  Widget _inPill(String s) {
    switch (s) {
      case 'Present':
        return StatusPill.present(s);
      case 'Late':
        return StatusPill.late(s);
      case 'Absent':
        return StatusPill.absent(s);
      default:
        return StatusPill.neutral(s);
    }
  }

  Widget _outPill(String s) {
    switch (s) {
      case 'On time':
        return StatusPill.present(s);
      case 'Early leave':
        return StatusPill.late(s);
      case 'Missing':
        return StatusPill.absent(s);
      default:
        return StatusPill.neutral(s);
    }
  }

  Widget _legend(Color color, String text) => Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.bodySoft),
        ],
      );

  Widget _attentionRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BloomCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: AppTextStyles.body)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: count == 0 ? AppColors.neutralBg : AppColors.lateBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: count == 0 ? AppColors.inkSoft : AppColors.late,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}