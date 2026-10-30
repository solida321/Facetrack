import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

/// Circle with the person's initials (for example "Dara Chan" -> "DC").
class AppAvatar extends StatelessWidget {
  final String name;
  final double size;

  /// Solid green circle with white letters (profile header).
  final bool filled;

  /// Grey circle (inactive person).
  final bool muted;

  const AppAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.filled = false,
    this.muted = false,
  });

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? AppColors.primary
        : (muted ? AppColors.neutralBg : AppColors.primarySoft);
    final fg = filled
        ? Colors.white
        : (muted ? AppColors.inkSoft : AppColors.primaryDeep);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        _initials,
        style: TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
          color: fg,
        ),
      ),
    );
  }
}
