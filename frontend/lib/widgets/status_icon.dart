import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import 'status_pill.dart';

/// The round icon at the start of a shift or attendance row.
/// Pass the status: 'present', 'late' or 'absent'. Anything else (null,
/// "upcoming") shows the plain clock.
/// The three icons come from [StatusIcons] in status_pill.dart.
class StatusIcon extends StatelessWidget {
  final String? status;
  final double size;

  const StatusIcon({super.key, required this.status, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final Color bg;
    switch (status) {
      case 'present':
        icon = StatusIcons.present;
        color = AppColors.present;
        bg = AppColors.presentBg;
        break;
      case 'late':
        icon = StatusIcons.late;
        color = AppColors.late;
        bg = AppColors.lateBg;
        break;
      case 'absent':
        icon = StatusIcons.absent;
        color = AppColors.absent;
        bg = AppColors.absentBg;
        break;
      default:
        icon = Icons.schedule_rounded;
        color = AppColors.primaryDeep;
        bg = AppColors.primarySoft;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}