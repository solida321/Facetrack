import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/attendance_record_model.dart';
import '../correction/correction_request_screen.dart';
import '../../../widgets/bloom_card.dart';
import '../../../widgets/info_banner.dart';
import '../../../widgets/outline_button.dart';
import '../../../widgets/status_pill.dart';

class AttendanceDetailScreen extends StatelessWidget {
  final AttendanceRecordModel record;
  const AttendanceDetailScreen({super.key, required this.record});

  bool _isPastDay(DateTime day) {
    final now = DateTime.now();
    return DateTime(day.year, day.month, day.day).isBefore(DateTime(now.year, now.month, now.day));
  }

  String _time(DateTime? t) => t == null ? '—' : DateFormatter.time(t);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Attendance detail', style: AppTextStyles.heading),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BloomCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    _row('Check-in', _time(record.checkInTime)),
                    const Divider(height: 1, color: AppColors.line),
                    _row('Check-out', record.missingCheckout ? 'Missing' : _time(record.checkOutTime)),
                    const Divider(height: 1, color: AppColors.line),
                    _statusRow(record.status),
                    if (record.leftEarly) ...[
                      const Divider(height: 1, color: AppColors.line),
                      _row('Note', 'Left early'),
                    ],
                  ],
                ),
              ),
              if (record.missingCheckout) ...[
                const SizedBox(height: 14),
                const InfoBanner(
                  icon: Icons.info_outline_rounded,
                  title: 'You did not check out',
                  subtitle: 'Tap "Report a mistake" and enter your real check-out time.',
                  tone: BannerTone.warning,
                ),
              ],
              const Spacer(),
              AppOutlineButton(
                label: 'Report a mistake',
                icon: Icons.edit_note_rounded,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CorrectionRequestScreen(
                      attendanceRecordId: record.id,
                      attendanceDate: record.attendanceDate,
                      currentStatus: record.status,
                      checkInTime: record.checkInTime,
                      // Ask for a check-out time only when it was really forgotten:
                      // flagged missing, or a past day with a check-in but no check-out.
                      askCheckOut: record.missingCheckout ||
                          (record.checkInTime != null &&
                              record.checkOutTime == null &&
                              _isPastDay(record.attendanceDate)),
                    ),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySoft),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  // Same row as above, but the value is a coloured pill instead of plain text.
  Widget _statusRow(String? status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Status', style: AppTextStyles.bodySoft),
          _pill(status),
        ],
      ),
    );
  }

  StatusPill _pill(String? status) {
    switch (status) {
      case 'present':
        return StatusPill.present('Present');
      case 'late':
        return StatusPill.late('Late');
      case 'absent':
        return StatusPill.absent('Absent');
      default:
        return StatusPill.neutral(status ?? '—');
    }
  }
}