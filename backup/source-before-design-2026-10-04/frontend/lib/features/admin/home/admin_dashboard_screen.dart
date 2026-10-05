import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/network/correction_api.dart';
import '../../../core/network/leave_api.dart';
import '../../../core/network/user_api.dart';
import '../../../widgets/stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _activeUsers = 0;
  int _pendingUsers = 0;
  int _checkedInToday = 0;
  int _lateToday = 0;
  int _pendingLeaves = 0;
  int _pendingCorrections = 0;
  int _onTimePercent = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _load() async {
    try {
      final users = await UserApi.getAll();
      final records = await AttendanceApi.getAll();
      final leaves = await LeaveApi.getAllLeaves();
      final corrections = await CorrectionApi.getAllCorrections();

      final now = DateTime.now();
      final todayRecords = records
          .where((r) => _sameDay(r.attendanceDate, now))
          .toList();
      final checkedInIds = todayRecords.map((r) => r.userId).toSet();
      final lateToday = todayRecords.where((r) => r.status == 'late').length;
      final presentToday = todayRecords
          .where((r) => r.status == 'present')
          .length;
      final attendedToday = presentToday + lateToday;

      if (!mounted) return;
      setState(() {
        _activeUsers = users.where((u) => u.status == 'active').length;
        _pendingUsers = users
            .where((u) => u.status == 'pending_approval')
            .length;
        _checkedInToday = checkedInIds.length;
        _lateToday = lateToday;
        _onTimePercent = attendedToday == 0
            ? 0
            : (presentToday / attendedToday * 100).round();
        _pendingLeaves = leaves.where((l) => l.status == 'pending').length;
        _pendingCorrections = corrections
            .where((c) => c.status == 'pending')
            .length;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.spa_rounded,
                            color: AppColors.primary,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'FaceTrack',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Company overview', style: AppTextStyles.heading),
                    const SizedBox(height: 2),
                    Text(
                      '${now.day}/${now.month}/${now.year}',
                      style: AppTextStyles.bodySoft,
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            value: '$_checkedInToday',
                            label: 'Checked in today',
                            color: AppColors.present,
                            background: AppColors.presentBg,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(
                            value: '$_lateToday',
                            label: 'Late today',
                            color: AppColors.late,
                            background: AppColors.lateBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            value: '$_activeUsers',
                            label: 'Active users',
                            color: AppColors.primary,
                            background: AppColors.primarySoft,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(
                            value: '$_pendingUsers',
                            label: 'Awaiting activation',
                            color: AppColors.late,
                            background: AppColors.lateBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    Text('On-time rate today', style: AppTextStyles.subheading),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: _onTimePercent / 100,
                        minHeight: 10,
                        backgroundColor: AppColors.line,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _checkedInToday == 0
                          ? 'No check-ins yet today.'
                          : '$_onTimePercent% of check-ins were on time',
                      style: AppTextStyles.bodySoft,
                    ),
                    const SizedBox(height: 22),

                    Text('Needs attention', style: AppTextStyles.subheading),
                    const SizedBox(height: 10),
                    _attentionRow('Leave requests waiting', _pendingLeaves),
                    _attentionRow(
                      'Correction requests waiting',
                      _pendingCorrections,
                    ),
                    _attentionRow(
                      'New accounts waiting for activation',
                      _pendingUsers,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _attentionRow(String label, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: count == 0 ? AppColors.line : AppColors.lateBg,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: count == 0 ? AppColors.inkSoft : AppColors.late,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
