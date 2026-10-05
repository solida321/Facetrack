import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

class StatusChipRow extends StatelessWidget {
  final int present;
  final int late;
  final int absent;
  const StatusChipRow({
    super.key,
    required this.present,
    required this.late,
    required this.absent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip('$present', 'Present', AppColors.present, AppColors.presentBg),
        const SizedBox(width: 7),
        _chip('$late', 'Late', AppColors.late, AppColors.lateBg),
        const SizedBox(width: 7),
        _chip('$absent', 'Absent', AppColors.absent, AppColors.absentBg),
      ],
    );
  }

  Widget _chip(String number, String label, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
