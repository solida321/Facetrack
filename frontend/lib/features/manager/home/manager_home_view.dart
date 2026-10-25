import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/network/correction_api.dart';
import '../../../core/network/leave_api.dart';
import '../../../core/network/user_api.dart';
import '../../../widgets/stat_card.dart';
import '../../notifications/notification_bell.dart';
import '../../reports/attendance_report_screen.dart';

class ManagerHomeView extends StatefulWidget {
  const ManagerHomeView({super.key});

  @override
  State<ManagerHomeView> createState() => _ManagerHomeViewState();
}  

class _ManagerHomeViewState extends State<ManagerHomeView> {
  int _teamSize = 0;
  int _checkedIn = 0;
  int _lateToday = 0;
  int _pendingLeaves = 0;
  int _pendingCorrections = 0;
  List<String> _notCheckedIn = [];
  bool _hasGroup = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _load() async {
    final user = context.read<AuthController>().currentUser;
    final groupId = user?.groupId;
    if (user == null || groupId == null) {
      setState(() {
        _hasGroup = false;
        _isLoading = false;
      });
      return;
    }

    try {
      final users = await UserApi.getAll();
      final team = users
          .where(
            (u) =>
                u.groupId == groupId &&
                u.id != user.id &&
                u.status == 'active' &&
                u.role.name == 'employee',
          )
          .toList();
      final teamIds = team.map((u) => u.id).toSet();

      final records = await AttendanceApi.getAll();
      final now = DateTime.now();
      final todayRecords = records
          .where(
            (r) =>
                teamIds.contains(r.userId) && _sameDay(r.attendanceDate, now),
          )
          .toList();
      final checkedInIds = todayRecords.map((r) => r.userId).toSet();

      final leaves = await LeaveApi.getByGroup(groupId);
      final corrections = await CorrectionApi.getByGroup(groupId);

      if (!mounted) return;
      setState(() {
        _hasGroup = true;
        _teamSize = team.length;
        _checkedIn = checkedInIds.length;
        _lateToday = todayRecords.where((r) => r.status == 'late').length;
        _pendingLeaves = leaves.where((l) => l.status == 'pending').length;
        _pendingCorrections = corrections
            .where((c) => c.status == 'pending')
            .length;
        _notCheckedIn = team
            .where((u) => !checkedInIds.contains(u.id))
            .map((u) => u.fullName)
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final now = DateTime.now();
    final firstName = user?.fullName.split(' ').first ?? '';
    final dateLabel =
        '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)} · Operations team';

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
                          'bloom',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.ink,
                          ),
                        ),
                        const Spacer(),
                        const NotificationBell(),
                        _rolePill(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Good morning, $firstName.',
                      style: AppTextStyles.headline,
                    ),
                    const SizedBox(height: 2),
                    Text(dateLabel, style: AppTextStyles.bodySoft),
                    const SizedBox(height: 14),
                    const AttendanceReportButton(),
                    const SizedBox(height: 18),

                    if (!_hasGroup)
                      Text(
                        'You are not assigned to a team yet. Contact your admin.',
                        style: AppTextStyles.bodySoft,
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              value: '$_teamSize',
                              label: 'Team members',
                              color: AppColors.primary,
                              background: AppColors.primarySoft,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              value: '$_checkedIn',
                              label: 'Checked in',
                              color: AppColors.present,
                              background: AppColors.presentBg,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              value: '$_lateToday',
                              label: 'Late',
                              color: AppColors.late,
                              background: AppColors.lateBg,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      Text(
                        'Waiting for your approval',
                        style: AppTextStyles.subheading,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              value: '$_pendingLeaves',
                              label: 'Leave requests',
                              color: AppColors.late,
                              background: AppColors.lateBg,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              value: '$_pendingCorrections',
                              label: 'Corrections',
                              color: AppColors.late,
                              background: AppColors.lateBg,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      Text(
                        'Not checked in yet',
                        style: AppTextStyles.subheading,
                      ),
                      const SizedBox(height: 10),
                      if (_notCheckedIn.isEmpty)
                        Text(
                          _teamSize == 0
                              ? 'No active team members yet.'
                              : 'Everyone has checked in.',
                          style: AppTextStyles.bodySoft,
                        )
                      else
                        ..._notCheckedIn.map(
                          (name) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.panel,
                              border: Border.all(color: AppColors.line),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.primarySoft,
                                  child: Text(
                                    name.isNotEmpty ? name[0] : '?',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'Sora',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _rolePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Text(
        'Manager',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _weekday(int day) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][day - 1];

  String _month(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}
