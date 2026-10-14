/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/network/schedule_api.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/schedule_model.dart';
import '../../attendance/schedule/today_schedule_screen.dart';

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
    // Dart weekday: Mon=1..Sun=7. Backend day_of_week: 0=Mon..6=Sun.
    if (s.dayOfWeek != null) {
      return s.dayOfWeek == now.weekday - 1;
    }
    if (s.specificDate != null) {
      return _sameDay(s.specificDate!, now);
    }
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
                        _rolePill(user?.role.name ?? 'Employee'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Hi, ${user?.fullName ?? ''}',
                      style: AppTextStyles.heading,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${now.day}/${now.month}/${now.year}',
                      style: AppTextStyles.bodySoft,
                    ),
                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.panel,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 58,
                                height: 58,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 58,
                                      height: 58,
                                      child: CircularProgressIndicator(
                                        value: rate / 100,
                                        strokeWidth: 5,
                                        backgroundColor: AppColors.primarySoft,
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                              AppColors.primary,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      '$rate%',
                                      style: const TextStyle(
                                        fontFamily: 'Sora',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your month, at a glance',
                                      style: TextStyle(
                                        fontFamily: 'Sora',
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'On-time rate this month',
                                      style: TextStyle(
                                        color: AppColors.inkSoft,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: AppColors.line),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _summaryStat('$present', 'Present'),
                              ),
                              Expanded(child: _summaryStat('$late', 'Late')),
                              Expanded(
                                child: _summaryStat('$absent', 'Absent'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text("Today's shifts", style: AppTextStyles.subheading),
                        Text(
                          '${_todaySchedules.length} shifts',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
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

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TodayScheduleScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Scan attendance',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w600,
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

  Widget _shiftCard(ScheduleModel s) {
    final record = _todayRecordFor(s.id);
    final checkedIn = record != null;
    final isLate = record?.status == 'late';

    final badgeText = !checkedIn ? 'Not yet' : (isLate ? 'Late' : 'Checked in');
    final badgeColor = !checkedIn
        ? AppColors.inkSoft
        : (isLate ? AppColors.late : AppColors.present);
    final badgeBg = !checkedIn
        ? AppColors.line
        : (isLate ? AppColors.lateBg : AppColors.presentBg);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${s.startTime.substring(0, 5)} – ${s.endTime.substring(0, 5)}',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(s.sessionName, style: AppTextStyles.bodySoft),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rolePill(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _summaryStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        Text(label, style: AppTextStyles.label),
      ],
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/network/schedule_api.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/schedule_model.dart';
import '../../../widgets/bloom_card.dart';
import '../../../widgets/status_pill.dart';
import '../../attendance/schedule/today_schedule_screen.dart';

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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TodayScheduleScreen(),
                            ),
                          );
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
    final isAbsent = record?.status == 'absent';
    final checkedIn = record != null && !isAbsent;
    final isLate = record?.status == 'late';

final pill = isAbsent
    ? StatusPill.absent('Absent')
    : !checkedIn
        ? StatusPill.neutral('Upcoming')
        : (isLate ? StatusPill.late('Checked in') : StatusPill.present('Checked in'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BloomCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
                if (checkedIn) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Checked in at ${record.checkInTime != null ? '${record.checkInTime!.hour.toString().padLeft(2, '0')}:${record.checkInTime!.minute.toString().padLeft(2, '0')}' : ''}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isLate ? AppColors.late : AppColors.present,
                    ),
                  ),
                ],
              ],
            ),
            pill,
          ],
        ),
      ),
    );
  }
}