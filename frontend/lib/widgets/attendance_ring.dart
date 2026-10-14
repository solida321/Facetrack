/*import 'package:flutter/material.dart';
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
}*/


import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

/// Light progress ring for the "Your month, at a glance" hero card.
/// Replaces the old dark-green AttendanceRing (same file name, new look).
class AttendanceRing extends StatelessWidget {
  final int percentage; // 0..100
  final double size;
  const AttendanceRing({super.key, required this.percentage, this.size = 84});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(percentage.clamp(0, 100) / 100),
        child: Center(
          child: Text(
            '$percentage%',
            style: const TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}