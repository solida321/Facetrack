import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/schedule_api.dart';
import '../../../core/network/attendance_api.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../widgets/bloom_card.dart';
import '../../../widgets/status_icon.dart';
import '../../../widgets/shift_action_card.dart';
import '../../../core/utils/date_formatter.dart';
import '../../face/scan/face_scan_screen.dart';
import '../check/check_out_screen.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_pill.dart';

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  List<ScheduleModel> _schedules = [];
  List<ScheduleModel> _todayShifts = []; // today's shifts, weekly or one-day
  List<AttendanceRecordModel> _records = [];
  bool _isLoading = true;
  String? _error;

  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    final groupId = user?.groupId;

    if (user == null || groupId == null) {
      setState(() {
        _error = 'You are not assigned to a group yet. Contact your admin.';
        _isLoading = false;
      });
      return;
    }

    try {
      final schedules = await ScheduleApi.getByGroup(groupId);
      final records = await AttendanceApi.getMyHistory(user.id);
      setState(() {
        _schedules = schedules.where((s) => s.dayOfWeek != null).toList();
        _todayShifts = schedules.where(_isToday).toList();
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load your schedule.';
        _isLoading = false;
      });
    }
  }

  bool _isToday(ScheduleModel s) {
    final now = DateTime.now();
    if (s.dayOfWeek != null) return s.dayOfWeek == now.weekday - 1;
    if (s.specificDate != null) return _sameDay(s.specificDate!, now);
    return false;
  }

  Future<void> _checkIn(ScheduleModel s) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FaceScanScreen(scheduleId: s.id)),
    );
    if (mounted) _load();
  }

  Future<void> _checkOut(AttendanceRecordModel record) async {
    await confirmAndCheckOut(context, record);
    if (mounted) _load();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Every schedule whose weekly day matches this date's weekday.
  List<ScheduleModel> _schedulesForDate(DateTime day) {
    final weekday = day.weekday - 1; // Dart Mon=1..Sun=7 -> backend 0=Mon..6=Sun
    return _schedules.where((s) => s.dayOfWeek == weekday).toList();
  }

  // Marker dots: table_calendar calls this once per visible day.
  List<ScheduleModel> _eventsForDay(DateTime day) => _schedulesForDate(day);

  AttendanceRecordModel? _recordFor(int scheduleId, DateTime day) {
    for (final r in _records) {
      if (r.scheduleId == scheduleId && _sameDay(r.attendanceDate, day)) {
        return r;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null
                ? EmptyState(
                    message: _error!,
                    icon: Icons.group_off_outlined,
                  )
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final selectedShifts = _schedulesForDate(_selectedDay);
    final totalMinutes = selectedShifts.fold<int>(0, (sum, s) {
      final start = _parseTime(s.startTime);
      final end = _parseTime(s.endTime);
      return sum + (end - start);
    });

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Your shifts.', style: AppTextStyles.headline),
        const SizedBox(height: 4),
        Text("Check in for today, and see your schedule below",
            style: AppTextStyles.bodySoft),
        const SizedBox(height: 18),

        // ---- Today ----
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's shifts", style: AppTextStyles.subheading),
            Text(
              '${_todayShifts.length} shift${_todayShifts.length == 1 ? '' : 's'}',
              style: AppTextStyles.bodySoft,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_todayShifts.isEmpty)
          const EmptyState(
            message: 'No shifts scheduled today.',
            icon: Icons.event_available_outlined,
          )
        else
          ..._todayShifts.map(
            (s) => ShiftActionCard(
              schedule: s,
              record: _recordFor(s.id, DateTime.now()),
              onCheckIn: () => _checkIn(s),
              onCheckOut: _checkOut,
            ),
          ),
        const SizedBox(height: 14),

        // ---- Calendar ----
        Text('My schedule', style: AppTextStyles.subheading),
        const SizedBox(height: 10),

        // ---- Week / Month toggle ----
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.line.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              _formatTab('Week', CalendarFormat.week),
              _formatTab('Month', CalendarFormat.month),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ---- Calendar ----
        BloomCard(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: TableCalendar<ScheduleModel>(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _format,
            selectedDayPredicate: (day) => _sameDay(day, _selectedDay),
            eventLoader: _eventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) => _focusedDay = focused,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.ink,
              ),
              leftChevronIcon:
                  Icon(Icons.chevron_left_rounded, color: AppColors.primary),
              rightChevronIcon:
                  Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 11,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                fontSize: 11,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: AppTextStyles.body,
              weekendTextStyle: AppTextStyles.body,
              todayDecoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 1.5),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              markersAlignment: Alignment.bottomCenter,
              markerSize: 5,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ---- Legend ----
        Row(
          children: [
            _legendDot(AppColors.primary, 'Selected'),
            const SizedBox(width: 14),
            _legendRing('Today'),
            const SizedBox(width: 14),
            _legendDot(AppColors.accent, 'Shift', small: true),
          ],
        ),
        const SizedBox(height: 24),

        // ---- Selected day detail ----
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fullDate(_selectedDay), style: AppTextStyles.subheading),
            if (_sameDay(_selectedDay, DateTime.now()))
              StatusPill.present('Today'),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          selectedShifts.isEmpty
              ? 'Day off — no shifts scheduled.'
              : '${selectedShifts.length} shift${selectedShifts.length == 1 ? '' : 's'} · ${(totalMinutes / 60).toStringAsFixed(0)} scheduled hours',
          style: AppTextStyles.bodySoft,
        ),
        const SizedBox(height: 14),

        if (selectedShifts.isEmpty)
          const EmptyState(
            message: 'Enjoy your day off.',
            icon: Icons.beach_access_rounded,
          )
        else
          ...selectedShifts.map((s) {
            final record = _recordFor(s.id, _selectedDay);
            final now = DateTime.now();
            final isPastDay =
                DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)
                    .isBefore(DateTime(now.year, now.month, now.day));
            // The round icon at the start of the card shows the status.
            final String? shiftStatus = record == null
                ? null
                : (record.status == 'absent'
                    ? 'absent'
                    : (record.status == 'late' ? 'late' : 'present'));
            final statusText = record == null
                ? (isPastDay ? 'No record' : 'Upcoming')
                : (record.status == 'absent' ? 'Absent' : null);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BloomCard(
                child: Row(
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
                        if (statusText != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: record?.status == 'absent' ? AppColors.absent : AppColors.inkSoft,
                            ),
                          ),
                        ],
                        if (record?.checkInTime != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Checked in at ${DateFormatter.time(record!.checkInTime!)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.present,
                            ),
                          ),
                        ],
                      ],
                    ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  int _parseTime(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _fullDate(DateTime d) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
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
      'December'
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  Widget _formatTab(String label, CalendarFormat format) {
    final active = _format == format;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _format = format),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.panel : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: active ? AppColors.primary : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label, {bool small = false}) {
    return Row(
      children: [
        Container(
          width: small ? 6 : 10,
          height: small ? 6 : 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodySoft),
      ],
    );
  }

  Widget _legendRing(String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 1.5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodySoft),
      ],
    );
  }
}