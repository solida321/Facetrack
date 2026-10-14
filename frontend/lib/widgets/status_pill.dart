/*import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  const StatusPill({super.key, required this.text, required this.color, required this.background});

  factory StatusPill.present(String text) => StatusPill(text: text, color: AppColors.present, background: AppColors.presentBg);
  factory StatusPill.late(String text) => StatusPill(text: text, color: AppColors.late, background: AppColors.lateBg);
  factory StatusPill.absent(String text) => StatusPill(text: text, color: AppColors.absent, background: AppColors.absentBg);
  factory StatusPill.neutral(String text) => StatusPill(text: text, color: AppColors.inkSoft, background: AppColors.line);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(100)),
      child: Text(text, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
    );
  }
}*/
import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

/// Small rounded status label. Old factories kept:
/// StatusPill.present / late / absent / neutral
/// New: StatusPill.pending, StatusPill.fromStatus('approved')
class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  const StatusPill({
    super.key,
    required this.text,
    required this.color,
    required this.background,
  });

  factory StatusPill.present(String text) => StatusPill(
      text: text, color: AppColors.present, background: AppColors.presentBg);
  factory StatusPill.late(String text) => StatusPill(
      text: text, color: AppColors.late, background: AppColors.lateBg);
  factory StatusPill.absent(String text) => StatusPill(
      text: text, color: AppColors.absent, background: AppColors.absentBg);
  factory StatusPill.neutral(String text) => StatusPill(
      text: text, color: AppColors.inkSoft, background: AppColors.line);
  factory StatusPill.pending(String text) => StatusPill.late(text);

  /// Map backend status strings to a pill, so screens don't repeat the switch.
  /// Shows the text capitalised: 'approved' -> 'Approved'.
  factory StatusPill.fromStatus(String status) {
    final label = status.isEmpty
        ? status
        : status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
    switch (status.toLowerCase()) {
      case 'present':
      case 'approved':
      case 'active':
        return StatusPill.present(label);
      case 'late':
      case 'pending':
      case 'pending_approval':
        return StatusPill.late(label);
      case 'absent':
      case 'rejected':
      case 'inactive':
        return StatusPill.absent(label);
      default:
        return StatusPill.neutral(label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}