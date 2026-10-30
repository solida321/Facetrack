import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

/// Row of round filter chips (All, Late, Absent ...). Scrolls sideways.
/// You keep the selected index in your own screen state.
class AppFilterChips extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  const AppFilterChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onSelected(i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: i == selected ? AppColors.primaryDeep : Colors.white,
                  border: Border.all(
                    color:
                        i == selected ? AppColors.primaryDeep : AppColors.line,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: i == selected ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
