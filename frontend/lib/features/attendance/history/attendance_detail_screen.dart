import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/attendance_record_model.dart';
import '../correction/correction_request_screen.dart';

class AttendanceDetailScreen extends StatelessWidget {
  final AttendanceRecordModel record;
  const AttendanceDetailScreen({super.key, required this.record});

  String _time(DateTime? t) => t == null
      ? '—'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
            _row('Check-in', _time(record.checkInTime)),
            _row('Check-out', record.missingCheckout ? 'Missing' : _time(record.checkOutTime)),
            _row('Status', record.status ?? '—'),
            if (record.leftEarly) _row('Note', 'Left early'),
            if (record.missingCheckout) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lateBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  'You did not check out. Tap "Report a mistake" and enter your real check-out time.',
                  style: AppTextStyles.bodySoft,
                ),
              ),
            ],
            const Spacer(),
            OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CorrectionRequestScreen(
                    attendanceRecordId: record.id,
                    attendanceDate: record.attendanceDate,
                    askCheckOut: record.missingCheckout || record.checkOutTime == null,
                  ),
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