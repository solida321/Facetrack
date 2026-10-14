import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_text_styles.dart';

/// A labeled row of selectable chips, with "All" always as the first option.
/// Generic over T so the same widget works for roles (String), teams (int
/// ids), days (int 0-6), or anything else with a label + a value.
class FilterChipGroup<T> extends StatelessWidget {
  final String label;
  final List<MapEntry<String, T>> options; // display text -> value
  final T? selected; // null means "All"
  final ValueChanged<T?> onChanged;

  const FilterChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('All', selected == null, () => onChanged(null)),
            ...options.map((o) => _chip(o.key, selected == o.value, () => onChanged(o.value))),
          ],
        ),
      ],
    );
  }

  Widget _chip(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.panel,
          border: Border.all(color: active ? AppColors.primary : AppColors.line),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.primary : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}