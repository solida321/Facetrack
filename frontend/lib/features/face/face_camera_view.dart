import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// The camera picture with an oval guide on top.
///
/// It shows the WHOLE camera frame (the same picture that is analysed), so
/// "what you see" and "what is checked" are the same. Before this, the preview
/// was cropped by its box: you saw only the middle of your face, but the photo
/// still contained the full frame.
///
/// The area outside the oval is dimmed. Keep your whole face inside the oval.
class FaceCameraView extends StatelessWidget {
  final CameraController controller;
  final Color guideColor;
  final String? hint;

  const FaceCameraView({
    super.key,
    required this.controller,
    this.guideColor = Colors.white,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = controller.value.aspectRatio; // width / height of the sensor (landscape)
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1 / ratio, // phone is held upright
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            CustomPaint(painter: _GuidePainter(guideColor)),
            if (hint != null && hint!.isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hint!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuidePainter extends CustomPainter {
  final Color color;
  _GuidePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final ovalWidth = size.width * 0.62;
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.47),
      width: ovalWidth,
      height: ovalWidth * 1.3,
    );

    final dim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addOval(oval),
    );
    canvas.drawPath(dim, Paint()..color = Colors.black45);
    canvas.drawOval(
      oval,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) => old.color != color;
}