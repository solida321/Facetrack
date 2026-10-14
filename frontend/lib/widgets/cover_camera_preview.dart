import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Shows the camera so it fills its parent without stretching.
/// The parent must have a bounded size (a sized Container, Expanded, etc.).
class CoverCameraPreview extends StatelessWidget {
  final CameraController controller;
  const CoverCameraPreview({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize;
    if (size == null) return const SizedBox.shrink();

    // previewSize is reported in landscape, so width/height are swapped
    // to describe the portrait picture the user actually sees.
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.height,
        height: size.width,
        child: CameraPreview(controller),
      ),
    );
  }
}