import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/attendance_api.dart';
import '../../../data/models/attendance_record_model.dart';
import 'attendance_detail_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<AttendanceRecordModel> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthController>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;
    try {
      final records = await AttendanceApi.getMyHistory(userId);
      setState(() { _records = records; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'present': return AppColors.present;
      case 'late': return AppColors.late;
      default: return AppColors.absent;
    }
  }

  Color _statusBg(String? status) {
    switch (status) {
      case 'present': return AppColors.presentBg;
      case 'late': return AppColors.lateBg;
      default: return AppColors.absentBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: Text('History', style: AppTextStyles.heading)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _records.isEmpty
              ? Center(child: Text('No attendance records yet.', style: AppTextStyles.bodySoft))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: _records.length,
                  separatorBuilder: (_, _) => const Divider(color: AppColors.line, height: 1),
                  itemBuilder: (context, i) {
                    final r = _records[i];
                    return ListTile(
  contentPadding: EdgeInsets.zero,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AttendanceDetailScreen(record: r)),
    );
  },
  title: Text('${r.attendanceDate.day}/${r.attendanceDate.month}/${r.attendanceDate.year}',
      style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 13)),
  subtitle: Text(
    r.checkInTime != null
        ? '${r.checkInTime!.hour.toString().padLeft(2, '0')}:${r.checkInTime!.minute.toString().padLeft(2, '0')}'
        : 'No record',
    style: AppTextStyles.bodySoft,
  ),
  trailing: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: _statusBg(r.status), borderRadius: BorderRadius.circular(100)),
    child: Text(r.status ?? '', style: TextStyle(color: _statusColor(r.status), fontWeight: FontWeight.w700, fontSize: 10.5)),
  ),
);
                  },
                ),
    );
  }
}