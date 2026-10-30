import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

/// The round icon of a notification. Pass the notification's `type`
/// and it picks the icon and the colors.
/// THE place to change a notification icon: one line per type in [_lookFor].
class NotificationIcon extends StatelessWidget {
  final String type;
  final double size;

  const NotificationIcon({super.key, required this.type, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final look = _lookFor(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: look.bg,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(look.icon, size: size * 0.5, color: look.color),
    );
  }
}

class _Look {
  final IconData icon;
  final Color color;
  final Color bg;
  const _Look(this.icon, this.color, this.bg);
}

_Look _lookFor(String type) {
  switch (type) {
    // Attendance
    case 'check_in_success':
      return const _Look(Icons.login_rounded, AppColors.present, AppColors.presentBg);
    case 'check_out_success':
      return const _Look(Icons.logout_rounded, AppColors.primaryDeep, AppColors.primarySoft);
    case 'late_warning':
      return const _Look(Icons.schedule_rounded, AppColors.late, AppColors.lateBg);
    case 'absent':
      return const _Look(Icons.person_off_rounded, AppColors.absent, AppColors.absentBg);
    case 'missing_checkout':
      return const _Look(Icons.timer_off_rounded, AppColors.late, AppColors.lateBg);
    // Corrections
    case 'correction_submitted':
      return const _Look(Icons.fact_check_rounded, AppColors.primaryDeep, AppColors.primarySoft);
    case 'correction_approved':
      return const _Look(Icons.check_circle_rounded, AppColors.present, AppColors.presentBg);
    case 'correction_rejected':
      return const _Look(Icons.cancel_rounded, AppColors.absent, AppColors.absentBg);
    // Leave
    case 'leave_approved':
      return const _Look(Icons.event_available_rounded, AppColors.present, AppColors.presentBg);
    case 'leave_rejected':
      return const _Look(Icons.event_busy_rounded, AppColors.absent, AppColors.absentBg);
    // Account
    case 'account_activated':
      return const _Look(Icons.verified_user_rounded, AppColors.present, AppColors.presentBg);
  }
  // A new leave request waiting for an approver (any other leave_ type).
  if (type.startsWith('leave_')) {
    return const _Look(Icons.inbox_rounded, AppColors.primaryDeep, AppColors.primarySoft);
  }
  return const _Look(Icons.notifications_rounded, AppColors.inkSoft, AppColors.neutralBg);
}