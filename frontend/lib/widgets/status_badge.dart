/*import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status; // present, late, absent
  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'present':
        return AppColors.present;
      case 'late':
        return AppColors.late;
      default:
        return AppColors.absent;
    }
  }

  Color get _bg {
    switch (status) {
      case 'present':
        return AppColors.presentBg;
      case 'late':
        return AppColors.lateBg;
      default:
        return AppColors.absentBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
        ),
      ),
    );
  }
}*/
