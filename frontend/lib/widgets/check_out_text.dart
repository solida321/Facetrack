import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/attendance_record_model.dart';

/// Two small lines for a shift card: CheckInText and CheckOutText.
///
/// CheckInText: "Checked in at 8:05 AM · On time" (green) or "· Late" (amber).
///
/// The "Checked out at ..." line of a shift card, coloured by how it ended:
///   on time        -> green
///   left early     -> amber, with "Left early"
///   never checked out (flagged by the system) -> red "Missing check-out"
/// Shows nothing while the person is still checked in (no check-out yet).
class CheckOutText extends StatelessWidget {
  final AttendanceRecordModel? record;
  const CheckOutText({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final r = record;
    if (r == null) return const SizedBox.shrink();

    final String text;
    final Color color;
    if (r.checkOutTime != null) {
      final time = DateFormatter.time(r.checkOutTime!);
      if (r.leftEarly) {
        text = 'Checked out at $time · Left early';
        color = AppColors.late;
      } else {
        text = 'Checked out at $time';
        color = AppColors.present;
      }
    } else if (r.missingCheckout) {
      text = 'Missing check-out';
      color = AppColors.absent;
    } else {
      return const SizedBox.shrink();
    }

    return Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color));
  }
}

/// The "Checked in at ..." line of a shift card, coloured by the check-in status:
///   on time -> green, "· On time"
///   late    -> amber, "· Late"
/// Shows nothing when there is no check-in time.
class CheckInText extends StatelessWidget {
  final AttendanceRecordModel? record;
  const CheckInText({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final r = record;
    if (r == null || r.checkInTime == null || r.status == 'absent') {
      return const SizedBox.shrink();
    }
    final late = r.status == 'late';
    final time = DateFormatter.time(r.checkInTime!);
    return Text(
      'Checked in at $time · ${late ? 'Late' : 'On time'}',
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: late ? AppColors.late : AppColors.present,
      ),
    );
  }
}