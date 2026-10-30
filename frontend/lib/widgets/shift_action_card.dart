import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../app/theme/app_text_styles.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/attendance_record_model.dart';
import '../data/models/schedule_model.dart';
import 'bloom_card.dart';
import 'status_icon.dart';
import 'check_out_text.dart';
import 'outline_button.dart';
import 'primary_button.dart';

/// One shift for today, with the ONE button that makes sense right now:
///   not checked in yet  -> Check in
///   checked in          -> Check out
///   checked out / absent -> no button, only the status
class ShiftActionCard extends StatelessWidget {
  final ScheduleModel schedule;
  final AttendanceRecordModel? record; // today's record for this shift, if any
  final VoidCallback onCheckIn;
  final void Function(AttendanceRecordModel record) onCheckOut;

  const ShiftActionCard({
    super.key,
    required this.schedule,
    required this.record,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    final checkInTime = record?.checkInTime;
    final checkOutTime = record?.checkOutTime;
    final isLate = record?.status == 'late';
    final isAbsent = record?.status == 'absent' && checkInTime == null;

    // The round icon at the start of the card shows the status.
    final String? shiftStatus = isAbsent
        ? 'absent'
        : checkInTime != null
            ? (isLate ? 'late' : 'present')
            : null;

    final Widget? action;
    if (isAbsent || checkOutTime != null) {
      action = null; // nothing left to do for this shift
    } else if (checkInTime != null && record != null) {
      action = AppOutlineButton(
        label: 'Check out',
        icon: Icons.logout_rounded,
        onPressed: () => onCheckOut(record!),
      );
    } else {
      action = PrimaryButton(
        label: 'Check in',
        icon: Icons.face_retouching_natural_rounded,
        onPressed: onCheckIn,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BloomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        schedule.sessionName,
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.shiftRange(schedule.startTime, schedule.endTime),
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
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
            if (action != null) ...[
              const SizedBox(height: 14),
              action,
            ],
          ],
        ),
      ),
    );
  }
}