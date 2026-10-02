import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/network/schedule_api.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/schedule_model.dart';
import '../../../widgets/stat_card.dart';
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

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(ScheduleModel s) {
    final now = DateTime.now();
    // Dart weekday: Mon=1..Sun=7. Backend day_of_week: 0=Mon..6=Sun.
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
      if (r.scheduleId == scheduleId && _sameDay(r.attendanceDate, now)) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final now = DateTime.now();

    final monthRecords = _records
        .where((r) => r.attendanceDate.year == now.year && r.attendanceDate.month == now.month)
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
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Text('Hi, ${user?.fullName ?? ''}', style: AppTextStyles.heading),
                    const SizedBox(height: 2),
                    Text('${now.day}/${now.month}/${now.year}', style: AppTextStyles.bodySoft),
                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                      child: Row(
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
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                                  ),
                                ),
                                Text('$rate%',
                                    style: const TextStyle(
                                        fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('On-time rate',
                                    style: TextStyle(fontFamily: 'Sora', color: Colors.white, fontWeight: FontWeight.w700)),
                                SizedBox(height: 2),
                                Text('This month', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: StatCard(value: '$present', label: 'Present', color: AppColors.present, background: AppColors.presentBg)),
                        const SizedBox(width: 8),
                        Expanded(child: StatCard(value: '$late', label: 'Late', color: AppColors.late, background: AppColors.lateBg)),
                        const SizedBox(width: 8),
                        Expanded(child: StatCard(value: '$absent', label: 'Absent', color: AppColors.absent, background: AppColors.absentBg)),
                      ],
                    ),
                    const SizedBox(height: 22),

                    Text("Today's shifts", style: AppTextStyles.subheading),
                    const SizedBox(height: 10),
                    if (user?.groupId == null)
                      Text('You are not assigned to a group yet. Contact your admin.', style: AppTextStyles.bodySoft)
                    else if (_todaySchedules.isEmpty)
                      Text('No shifts scheduled today.', style: AppTextStyles.bodySoft)
                    else
                      ..._todaySchedules.map(_shiftCard),

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TodayScheduleScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('Scan attendance',
                            style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, color: AppColors.accentInk)),
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
    final badgeColor = !checkedIn ? AppColors.inkSoft : (isLate ? AppColors.late : AppColors.present);
    final badgeBg = !checkedIn ? AppColors.line : (isLate ? AppColors.lateBg : AppColors.presentBg);

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
              Text('${s.startTime.substring(0, 5)} – ${s.endTime.substring(0, 5)}',
                  style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(s.sessionName, style: AppTextStyles.bodySoft),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(100)),
            child: Text(badgeText, style: TextStyle(color: badgeColor, fontWeight: FontWeight.w700, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}