import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

/// THE place to change the Present / Late / Absent icons.
/// Change one line here and every pill and box in the app follows.
class StatusIcons {
  StatusIcons._();
  static const IconData present = Icons.check_circle_rounded;
  static const IconData late = Icons.schedule_rounded;
  static const IconData absent = Icons.cancel_rounded;
}

/// Small round label with an icon: On time, Late, Absent, Pending ...
class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  final bool showDot;

  /// Shown instead of the dot when set.
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.text,
    required this.color,
    required this.background,
    this.showDot = true,
    this.icon,
  });

  factory StatusPill.present(String text) => StatusPill(
      text: text, color: AppColors.present, background: AppColors.presentBg, icon: StatusIcons.present);
  factory StatusPill.late(String text) => StatusPill(
      text: text, color: AppColors.late, background: AppColors.lateBg, icon: StatusIcons.late);
  factory StatusPill.absent(String text) => StatusPill(
      text: text, color: AppColors.absent, background: AppColors.absentBg, icon: StatusIcons.absent);
  factory StatusPill.neutral(String text) => StatusPill(
      text: text, color: AppColors.inkSoft, background: AppColors.neutralBg);

  /// One place that turns a status word from the server into a pill.
  /// Use this everywhere so the same status always looks the same.
  factory StatusPill.fromStatus(String status, {String? label}) {
    final s = status.toLowerCase();
    switch (s) {
      case 'present':
      case 'on_time':
      case 'approved':
      case 'active':
      case 'checked_in':
        return StatusPill.present(label ?? _label(s));
      case 'late':
      case 'early_leave':
      case 'pending':
      case 'pending_approval':
        return StatusPill.late(label ?? _label(s));
      case 'absent':
      case 'rejected':
      case 'missing':
      case 'missing_checkout':
        return StatusPill.absent(label ?? _label(s));
      default:
        return StatusPill.neutral(label ?? _label(s));
    }
  }

  static String _label(String s) {
    switch (s) {
      case 'on_time':
        return 'On time';
      case 'early_leave':
        return 'Early leave';
      case 'missing':
      case 'missing_checkout':
        return 'Missing check-out';
      case 'pending_approval':
        return 'Pending';
      case 'checked_in':
        return 'Checked in';
    }
    if (s.isEmpty) return s;
    final t = s.replaceAll('_', ' ');
    return t[0].toUpperCase() + t.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
          ] else if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}