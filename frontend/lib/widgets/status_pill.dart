import 'package:flutter/material.dart';
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
}