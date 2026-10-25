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
import '../../../widgets/bloom_card.dart';
import '../../../widgets/status_pill.dart';
import '../../attendance/check/check_out_screen.dart';
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            user?.role.name ?? 'Employee',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Good morning, $firstName.',
                      style: AppTextStyles.headline,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_weekdayMonth(now)} · ${user?.role.name ?? ''}',
                      style: AppTextStyles.bodySoft,
                    ),
                    const SizedBox(height: 20),

                    BloomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your month, at a glance',
                            style: AppTextStyles.subheading,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            attended == 0
                                ? 'No check-ins recorded yet this month.'
                                : 'A steady start. $present on time of $attended scheduled days.',
                            style: AppTextStyles.bodySoft,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                '$rate%',
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 26,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  'on time',
                                  style: AppTextStyles.bodySoft,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _statBlock('$present', 'Present'),
                              _statBlock('$late', 'Late'),
                              _statBlock('$absent', 'Absent'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

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
                      Text(
                        'You are not assigned to a group yet. Contact your admin.',
                        style: AppTextStyles.bodySoft,
                      )
                    else if (_todaySchedules.isEmpty)
                      Text(
                        'No shifts scheduled today.',
                        style: AppTextStyles.bodySoft,
                      )
                    else
                      ..._todaySchedules.map(_shiftCard),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Scan attendance',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statBlock(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          Text(label, style: AppTextStyles.bodySoft),
        ],
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

    final StatusPill pill;
    if (isAbsent) {
      pill = StatusPill.absent('Absent');
    } else if (checkOutTime != null) {
      pill = isLate ? StatusPill.late('Checked out') : StatusPill.present('Checked out');
    } else if (checkInTime != null) {
      pill = isLate ? StatusPill.late('Checked in') : StatusPill.present('Checked in');
    } else {
      pill = StatusPill.neutral('Upcoming');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BloomCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.sessionName,
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.startTime.substring(0, 5)} – ${s.endTime.substring(0, 5)}',
                        style: AppTextStyles.bodySoft,
                      ),
                      if (checkInTime != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Checked in at ${DateFormatter.time(checkInTime)}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isLate ? AppColors.late : AppColors.present,
                          ),
                        ),
                      ],
                      if (checkOutTime != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Checked out at ${DateFormatter.time(checkOutTime)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                pill,
              ],
            ),
            // The Check out button only appears while the user is checked in
            // and has not checked out yet.
            if (record != null && checkInTime != null && checkOutTime == null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openCheckOut(record),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Check out'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
