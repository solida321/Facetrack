import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/attendance_record_model.dart';
import '../correction/correction_request_screen.dart';

class AttendanceDetailScreen extends StatelessWidget {
  final AttendanceRecordModel record;
  const AttendanceDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: Text('Attendance detail', style: AppTextStyles.heading)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Check-in', record.checkInTime != null
                ? '${record.checkInTime!.hour.toString().padLeft(2, '0')}:${record.checkInTime!.minute.toString().padLeft(2, '0')}'
                : '—'),
            _row('Check-out', record.checkOutTime != null
                ? '${record.checkOutTime!.hour.toString().padLeft(2, '0')}:${record.checkOutTime!.minute.toString().padLeft(2, '0')}'
                : '—'),
            _row('Status', record.status ?? '—'),
            const Spacer(),
            OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CorrectionRequestScreen(attendanceRecordId: record.id),
                ));
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              child: const Text('Report a mistake', style: TextStyle(color: AppColors.primary, fontFamily: 'Sora', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySoft),
          Text(value, style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}