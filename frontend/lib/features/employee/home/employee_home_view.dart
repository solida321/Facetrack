import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/network/schedule_api.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/schedule_model.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/attendance_ring.dart';
import '../../../widgets/bloom_card.dart';
import '../../../widgets/status_icon.dart';
import '../../../widgets/check_out_text.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/outline_button.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/status_chip_row.dart';
import '../../attendance/check/check_out_screen.dart';
import '../../attendance/history/attendance_history_screen.dart';
import '../../attendance/schedule/today_schedule_screen.dart';
import '../../notifications/notification_bell.dart';


class EmployeeHomeView extends StatefulWidget {
  const EmployeeHomeView({super.key});

  @override
  State<EmployeeHomeView> createState() => _EmployeeHomeViewState();
}

class _EmployeeHomeViewState extends State<EmployeeHomeView> {
  List<AttendanceRecordModel> _records = [];
  List<ScheduleModel> _todaySchedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(ScheduleModel s) {
    final now = DateTime.now();
    if (s.dayOfWeek != null) return s.dayOfWeek == now.weekday - 1;
    if (s.specificDate != null) return _sameDay(s.specificDate!, now);
    return false;
  }

  Future<void> _load() async {
    final user = context.read<AuthController>().currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final records = await AttendanceApi.getMyHistory(user.id);
      List<ScheduleModel> today = [];

      if (user.groupId != null) {
        final all = await ScheduleApi.getByGroup(user.groupId!);
        today = all.where(_isToday).toList();
      }

      if (!mounted) return;

      setState(() {
        _records = records;
        _todaySchedules = today;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  AttendanceRecordModel? _todayRecordFor(int scheduleId) {
    final now = DateTime.now();

    for (final r in _records) {
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

  String _weekdayMonth(DateTime d) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return weekdays[d.weekday - 1];
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

    final monthRecords = _records
        .where(
          (r) =>
              r.attendanceDate.year == now.year &&
              r.attendanceDate.month == now.month,
        )
        .toList();

    final present = monthRecords.where((r) => r.status == 'present').length;
    final late = monthRecords.where((r) => r.status == 'late').length;
    final absent = monthRecords.where((r) => r.status == 'absent').length;
    final attended = present + late;
    final rate = attended == 0 ? 0 : (present / attended * 100).round();
    final firstName = user?.fullName.split(' ').first ?? '';

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
                              Text(
                                '${_weekdayMonth(now)} · ${user?.role.name ?? ''}',
                                style: AppTextStyles.bodySoft,
                              ),
                            ],
                          ),
                        ),
                        const NotificationBell(),
                      ],
                    ),
                    const SizedBox(height: 20),

                    AttendanceRing(percentage: rate),
                    const SizedBox(height: 10),
                    Text(
                      attended == 0
                          ? 'No check-ins recorded yet this month.'
                          : 'A steady start. $present on time of $attended scheduled days.',
                      style: AppTextStyles.bodySoft,
                    ),
                    const SizedBox(height: 12),
                    StatusChipRow(
                      present: present,
                      late: late,
                      absent: absent,
                      onTap: _openHistory,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Today's shifts", style: AppTextStyles.subheading),
                        Text(
                          '${_todaySchedules.length} shift${_todaySchedules.length == 1 ? '' : 's'}',
                          style: AppTextStyles.bodySoft,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (user?.groupId == null)
                      const EmptyState(
                        message:
                            'You are not assigned to a group yet. Contact your admin.',
                        icon: Icons.group_off_outlined,
                      )
                    else if (_todaySchedules.isEmpty)
                      const EmptyState(
                        message: 'No shifts scheduled today.',
                        icon: Icons.event_available_outlined,
                      )
                    else
                      ..._todaySchedules.map(_shiftCard),

                    const SizedBox(height: 20),

                    PrimaryButton(
                      label: 'Scan attendance',
                      icon: Icons.face_retouching_natural_rounded,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TodayScheduleScreen(),
                          ),
                        );
                        // Coming back from a check-in: refresh the shift cards.
                        if (mounted) _load();
                      },
                    ),
                    const SizedBox(height: 10),
                    AppOutlineButton(
                      label: 'My attendance history',
                      icon: Icons.history_rounded,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

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