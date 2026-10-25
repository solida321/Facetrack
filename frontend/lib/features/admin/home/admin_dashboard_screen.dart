import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/network/correction_api.dart';
import '../../../core/network/group_api.dart';
import '../../../core/network/leave_api.dart';
import '../../../core/network/user_api.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/user_model.dart';
import '../../../widgets/bloom_card.dart';
import '../../../widgets/stat_card.dart';
import '../export/export_screen.dart';
import '../../notifications/notification_bell.dart';
import '../../reports/attendance_report_screen.dart';



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
  bool _isLoading = true;
  int _days = 7; // chart period: 7 or 30

  static const _absentBg = Color(0xFFF8E2DF);

  @override
  void initState() {
    super.initState();
    _load();
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
      final leaves = await LeaveApi.getAllLeaves();
      final corrections = await CorrectionApi.getAllCorrections();
      if (!mounted) return;

      final t = DateTime.now();
      final today = DateTime(t.year, t.month, t.day);

      setState(() {
        _users = users;
        _records = records;
        _groups = groups;
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

  DateTime get _since {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: _days - 1));
  }

  List<AttendanceRecordModel> get _inRange =>
      _records.where((r) => !r.attendanceDate.isBefore(_since)).toList();

  int _count(List<AttendanceRecordModel> list, String status) => list.where((r) => r.status == status).length;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final range = _inRange;
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Text('Dashboard', style: AppTextStyles.headline),
                    const SizedBox(height: 2),
                    Text('${now.day}/${now.month}/${now.year} · All teams', style: AppTextStyles.bodySoft),
                    const SizedBox(height: 14),
                    const AttendanceReportButton(),
                    const SizedBox(height: 18),

                    // ---- Today ----
                    Row(
                      children: [
                        Expanded(child: StatCard(value: '${today.where((r) => r.status == 'present' || r.status == 'late').length}', label: 'Checked in today', color: AppColors.present, background: AppColors.presentBg)),
                        const SizedBox(width: 8),
                        Expanded(child: StatCard(value: '${_count(today, 'late')}', label: 'Late today', color: AppColors.late, background: AppColors.lateBg)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: StatCard(value: '${_count(today, 'absent')}', label: 'Absent today', color: AppColors.absent, background: _absentBg)),
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

                    // ---- Period + export ----
                    Row(
                      children: [
                        _periodChip('7 days', 7),
                        const SizedBox(width: 8),
                        _periodChip('30 days', 30),
                        const Spacer(),
                        const NotificationBell(),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(border: Border.all(color: AppColors.primary), borderRadius: BorderRadius.circular(100)),
                            child: const Row(
                              children: [
                                Icon(Icons.download_rounded, size: 16, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text('Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ),
                      ],
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
    final start = _since;
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
            interval: _days == 7 ? 1 : 5,
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
          barWidth: 2.5,
          dotData: FlDotData(show: _days == 7),
          belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.08)),
        ),
      ],
    ));
  }

  Widget _periodChip(String label, int days) {
    final active = _days == days;
    return GestureDetector(
      onTap: () => setState(() => _days = days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.panel,
          border: Border.all(color: active ? AppColors.primary : AppColors.line),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? AppColors.primary : AppColors.inkSoft)),
      ),
    );
  }

  Widget _legend(Color color, String text) => Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.bodySoft),
        ],
      );

  Widget _attentionRow(String label, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: count == 0 ? AppColors.line : AppColors.lateBg, borderRadius: BorderRadius.circular(100)),
            child: Text('$count', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: count == 0 ? AppColors.inkSoft : AppColors.late)),
          ),
        ],
      ),
    );
  }
}