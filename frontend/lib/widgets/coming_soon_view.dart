import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_text_styles.dart';

class ComingSoonView extends StatelessWidget {
  final String label;
  const ComingSoonView({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('$label — coming soon', style: AppTextStyles.bodySoft),
      ),
    );
  }
}