import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

class AttendanceRing extends StatelessWidget {
  final int percentage;
  const AttendanceRing({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(19)),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [AppColors.accent, Colors.white.withValues(alpha: 0.22)],
                stops: [percentage / 100, percentage / 100],
              ),
            ),
            child: Center(
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                child: Center(
                  child: Text('$percentage%', style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text('Attendance rate', style: TextStyle(fontFamily: 'Sora', color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}