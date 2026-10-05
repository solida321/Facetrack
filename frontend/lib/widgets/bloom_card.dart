import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

/// The bordered card container used everywhere in the redesign —
/// stat blocks, list rows, sections. One visual unit, reused.
class BloomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const BloomCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}