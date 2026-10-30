import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

enum BannerTone { good, warning, bad }

/// Rounded message strip: location verified, face not recognised, etc.
class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final BannerTone tone;

  const InfoBanner({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.tone = BannerTone.good,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    switch (tone) {
      case BannerTone.good:
        fg = AppColors.primaryDeep;
        bg = AppColors.primarySoft;
        break;
      case BannerTone.warning:
        fg = AppColors.late;
        bg = AppColors.lateBg;
        break;
      case BannerTone.bad:
        fg = AppColors.absent;
        bg = AppColors.absentBg;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: fg,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      color: AppColors.ink,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
