import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import 'status_pill.dart';

class StatusChipRow extends StatelessWidget {
  final int present;
  final int late;
  final int absent;

  /// Called with 'present', 'late' or 'absent' when a box is tapped.
  /// Leave it null and the boxes are not tappable.
  final ValueChanged<String>? onTap;

  const StatusChipRow({
    super.key,
    required this.present,
    required this.late,
    required this.absent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip('$present', 'Present', AppColors.present, AppColors.presentBg, 'present', StatusIcons.present),
        const SizedBox(width: 8),
        _chip('$late', 'Late', AppColors.late, AppColors.lateBg, 'late', StatusIcons.late),
        const SizedBox(width: 8),
        _chip('$absent', 'Absent', AppColors.absent, AppColors.absentBg, 'absent', StatusIcons.absent),
      ],
    );
  }

  Widget _chip(String number, String label, Color color, Color bg, String key, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap == null ? null : () => onTap!(key),
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w800,
                fontSize: 24,
                height: 1.1,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}