import 'package:flutter/material.dart';
import '../app/theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final String message;
  const EmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, style: AppTextStyles.bodySoft));
  }
}