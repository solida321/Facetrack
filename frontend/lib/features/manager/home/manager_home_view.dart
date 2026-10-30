import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/network/correction_api.dart';
import '../../../core/network/leave_api.dart';
import '../../../core/network/schedule_api.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/schedule_model.dart';
import '../../attendance/check/check_out_screen.dart';
import '../../attendance/schedule/today_schedule_screen.dart';
import '../../../core/network/user_api.dart';
import '../../../widgets/stat_card.dart';
import '../../attendance/history/attendance_history_screen.dart';
import '../../notifications/notification_bell.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/attendance_ring.dart';
import '../../../widgets/status_chip_row.dart';
import '../../../widgets/bloom_card.dart';
import '../../../widgets/status_icon.dart';
import '../../../widgets/check_out_text.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/outline_button.dart';
import '../../../widgets/primary_button.dart';

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

  // The manager's OWN work: today's shifts and own attendance (same as an employee).
  List<AttendanceRecordModel> _myRecords = [];
  List<ScheduleModel> _todaySchedules = [];
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

      // Own shifts and own records, so the manager can check in and out too.
      final myRecords = await AttendanceApi.getMyHistory(user.id);
      final allShifts = await ScheduleApi.getByGroup(groupId);
      final myToday = allShifts.where(_isToday).toList();

      final leaves = await LeaveApi.getByGroup(groupId);
      final corrections = await CorrectionApi.getByGroup(groupId);

      if (!mounted) return;
      setState(() {
        _hasGroup = true;
        _myRecords = myRecords;
        _todaySchedules = myToday;
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

  bool _isToday(ScheduleModel s) {
    final now = DateTime.now();
    if (s.dayOfWeek != null) return s.dayOfWeek == now.weekday - 1;
    if (s.specificDate != null) return _sameDay(s.specificDate!, now);
    return false;
  }

  AttendanceRecordModel? _todayRecordFor(int scheduleId) {
    final now = DateTime.now();

    for (final r in _myRecords) {
      if (r.scheduleId == scheduleId && _sameDay(r.attendanceDate, now)) {
        return r;
      }
    }

    return null;
  }

  /// Asks "are you sure?", then opens the check-out screen, then refreshes
  /// Home so the shift card flips from "Check out" to "Checked out at ...".
  Future<void> _openCheckOut(AttendanceRecordModel record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Check out now?'),
        content: const Text('This records the end of your shift using your current location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Check out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckOutScreen(attendanceRecordId: record.id),
      ),
    );
    if (mounted) _load();
  }

  /// Tapping Present / Late / Absent opens the history, filtered, for this month.
  void _openHistory(String status) {
    final now = DateTime.now();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceHistoryScreen(
          initialStatus: status,
          initialRange: DateTimeRange(start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month, now.day)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final now = DateTime.now();
    final firstName = user?.fullName.split(' ').first ?? '';
    final dateLabel =
        '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)} · Operations team';

    // The manager's OWN attendance this month (same numbers an employee sees).
    final myMonth = _myRecords
        .where((r) => r.attendanceDate.year == now.year && r.attendanceDate.month == now.month)
        .toList();
    final myPresent = myMonth.where((r) => r.status == 'present').length;
    final myLate = myMonth.where((r) => r.status == 'late').length;
    final myAbsent = myMonth.where((r) => r.status == 'absent').length;
    final myAttended = myPresent + myLate;
    final myRate = myAttended == 0 ? 0 : (myPresent / myAttended * 100).round();

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
                        AppAvatar(name: user?.fullName ?? '', size: 48, filled: true),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good morning, $firstName.',
                                style: AppTextStyles.headline,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(dateLabel, style: AppTextStyles.bodySoft),
                            ],
                          ),
                        ),
                        const NotificationBell(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ---- My own attendance this month ----
                    Text('My attendance this month', style: AppTextStyles.subheading),
                    const SizedBox(height: 10),
                    AttendanceRing(percentage: myRate),
                    const SizedBox(height: 10),
                    Text(
                      myAttended == 0
                          ? 'No check-ins recorded yet this month.'
                          : '$myPresent on time of $myAttended attended days.',
                      style: AppTextStyles.bodySoft,
                    ),
                    const SizedBox(height: 12),
                    StatusChipRow(
                      present: myPresent,
                      late: myLate,
                      absent: myAbsent,
                      onTap: _openHistory,
                    ),
                    const SizedBox(height: 22),

                    if (_hasGroup) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("My shifts today", style: AppTextStyles.subheading),
                          Text(
                            '${_todaySchedules.length} shift${_todaySchedules.length == 1 ? '' : 's'}',
                            style: AppTextStyles.bodySoft,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_todaySchedules.isEmpty)
                        const EmptyState(
                          message: 'No shifts scheduled for you today.',
                          icon: Icons.event_available_outlined,
                        )
                      else
                        ..._todaySchedules.map(_shiftCard),
                      const SizedBox(height: 6),
                      PrimaryButton(
                        label: 'Scan attendance',
                        icon: Icons.face_retouching_natural_rounded,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TodayScheduleScreen()),
                          );
                          // Coming back from a check-in: refresh the shift cards.
                          if (mounted) _load();
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    // The manager's OWN attendance (not the team's).
                    AppOutlineButton(
                      label: 'My attendance history',
                      icon: Icons.history_rounded,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (!_hasGroup)
                      const EmptyState(
                        message: 'You are not assigned to a team yet. Contact your admin.',
                        icon: Icons.group_off_outlined,
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              value: '$_teamSize',
                              label: 'Team members',
                              color: AppColors.primaryDeep,
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
                      const SizedBox(height: 24),

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
                      const SizedBox(height: 24),

                      Text(
                        'Not checked in yet',
                        style: AppTextStyles.subheading,
                      ),
                      const SizedBox(height: 10),
                      if (_notCheckedIn.isEmpty)
                        EmptyState(
                          message: _teamSize == 0
                              ? 'No active team members yet.'
                              : 'Everyone has checked in.',
                          icon: Icons.groups_2_outlined,
                        )
                      else
                        ..._notCheckedIn.map(
                          (name) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: BloomCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  AppAvatar(name: name, size: 40),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontFamily: 'Sora',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _shiftCard(ScheduleModel s) {
    final record = _todayRecordFor(s.id);

    // Three simple facts decide what the card shows:
    final checkInTime = record?.checkInTime;   // null when absent / not yet checked in
    final checkOutTime = record?.checkOutTime; // null until the user checks out
    final isLate = record?.status == 'late';
    final isAbsent = record?.status == 'absent' && checkInTime == null;

    // The round icon at the start of the card shows the status.
    final String? shiftStatus = isAbsent
        ? 'absent'
        : checkInTime != null
            ? (isLate ? 'late' : 'present')
            : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BloomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusIcon(status: shiftStatus),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.sessionName,
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.shiftRange(s.startTime, s.endTime),
                        style: AppTextStyles.bodySoft,
                      ),
                      if (isAbsent) ...[
                        const SizedBox(height: 2),
                        const Text(
                          'Absent',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.absent),
                        ),
                      ] else if (checkInTime == null) ...[
                        const SizedBox(height: 2),
                        const Text(
                          'Upcoming',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                        ),
                      ],
                      if (checkInTime != null) ...[
                        const SizedBox(height: 2),
                        CheckInText(record: record),
                      ],
                      if (checkOutTime != null || (record?.missingCheckout ?? false)) ...[
                        const SizedBox(height: 2),
                        CheckOutText(record: record),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // The Check out button only appears while the user is checked in
            // and has not checked out yet.
            if (record != null && checkInTime != null && checkOutTime == null) ...[
              const SizedBox(height: 14),
              AppOutlineButton(
                label: 'Check out',
                icon: Icons.logout_rounded,
                onPressed: () => _openCheckOut(record),
              ),
            ],
          ],
        ),
      ),
    );
  }
}