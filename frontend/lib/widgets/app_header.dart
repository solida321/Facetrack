import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../features/notifications/notification_bell.dart';

/// The top bar of every home screen: logo + name on the left,
/// the role pill and the notification bell on the right.
/// It sits ABOVE the scrolling list, so it never scrolls away.
///
/// Use:  AppHeader(role: 'Manager')   // or 'Employee' / 'Admin'
class AppHeader extends StatelessWidget {
  final String role;
  const AppHeader({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.face_unlock_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'AttendFace',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.ink,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.presentBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.present,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const NotificationBell(),
        ],
      ),
    );
  }
}