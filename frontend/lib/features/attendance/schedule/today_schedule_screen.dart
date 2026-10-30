import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/network/schedule_api.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/schedule_model.dart';
import '../../face/scan/face_scan_screen.dart';
import '../check/check_out_screen.dart';
import '../../../widgets/shift_action_card.dart';
import '../../../widgets/back_circle_button.dart';
import '../../../widgets/empty_state.dart';

class TodayScheduleScreen extends StatefulWidget {
  const TodayScheduleScreen({super.key});

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen> {
  List<ScheduleModel> _schedules = [];
  List<AttendanceRecordModel> _records = []; // own records, to know what is already done
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final auth = context.read<AuthController>();
    final groupId = auth.currentUser?.groupId;

    if (groupId == null) {
      setState(() {
        _error = 'You are not assigned to a group yet. Contact your admin.';
        _isLoading = false;
      });
      return;
    }

    try {
      final all = await ScheduleApi.getByGroup(groupId);
      final now = DateTime.now();
      final today =
          now.weekday - 1; // Dart: Mon=1..Sun=7 -> backend: 0=Mon..6=Sun

      final todaysSchedules = all.where((s) {
        if (s.dayOfWeek != null) return s.dayOfWeek == today;
        if (s.specificDate != null) {
          return s.specificDate!.year == now.year &&
              s.specificDate!.month == now.month &&
              s.specificDate!.day == now.day;
        }
        return false;
      }).toList();

      // Own records, so a shift that is already checked in shows Check out, not Check in.
      var records = <AttendanceRecordModel>[];
      final userId = auth.currentUser?.id;
      if (userId != null) {
        try {
          records = await AttendanceApi.getMyHistory(userId);
        } catch (_) {}
      }

      setState(() {
        _schedules = todaysSchedules;
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

  AttendanceRecordModel? _todayRecordFor(int scheduleId) {
    final now = DateTime.now();
    for (final r in _records) {
      final d = r.attendanceDate;
      if (r.scheduleId == scheduleId && d.year == now.year && d.month == now.month && d.day == now.day) {
        return r;
      }
    }
    return null;
  }

  Future<void> _checkIn(ScheduleModel s) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FaceScanScreen(scheduleId: s.id)),
    );
    if (mounted) _loadSchedules();
  }

  Future<void> _checkOut(AttendanceRecordModel record) async {
    await confirmAndCheckOut(context, record);
    if (mounted) _loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  const BackCircleButton(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Today\'s schedule', style: AppTextStyles.headline),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return EmptyState(message: _error!, icon: Icons.group_off_outlined);
    }
    if (_schedules.isEmpty) {
      return const EmptyState(
        message: 'No shifts scheduled today.',
        icon: Icons.event_available_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: _schedules.length + 1,
      itemBuilder: (context, index) {
        if (index == _schedules.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Face and location are checked when you press Check in.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySoft,
            ),
          );
        }
        final s = _schedules[index];
        return ShiftActionCard(
          schedule: s,
          record: _todayRecordFor(s.id),
          onCheckIn: () => _checkIn(s),
          onCheckOut: _checkOut,
        );
      },
    );
  }
}