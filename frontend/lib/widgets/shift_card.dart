import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

class ShiftCard extends StatelessWidget {
  final String time;
  final String name;
  final String tag;
  final bool active;
  const ShiftCard({
    super.key,
    required this.time,
    required this.name,
    required this.tag,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: active ? AppColors.primary : AppColors.line),
        color: active ? AppColors.primarySoft : AppColors.panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
