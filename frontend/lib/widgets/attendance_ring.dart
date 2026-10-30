import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

class AttendanceRing extends StatelessWidget {
  final int percentage;
  const AttendanceRing({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    final p = percentage.clamp(0, 100) / 100;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: p,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Attendance rate',
              style: TextStyle(
                fontFamily: 'Sora',
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
