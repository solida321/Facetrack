import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

/// Round white back button used at the top of pushed screens.
class BackCircleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const BackCircleButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed ?? () => Navigator.maybePop(context),
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.chevron_left_rounded,
                size: 28, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
