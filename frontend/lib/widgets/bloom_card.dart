/*import 'package:flutter/material.dart';
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
}*/


import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

/// The card container used everywhere in the redesign.
/// - default: white card with a thin border
/// - tinted: pale-green "hero" card (e.g. "Your month, at a glance")
/// Old callers still work: BloomCard(child: ..., padding: ...)
class BloomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool tinted;
  final VoidCallback? onTap;

  const BloomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.tinted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Material(
      color: tinted ? AppColors.primarySoft : AppColors.panel,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: tinted ? Colors.transparent : AppColors.line,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}