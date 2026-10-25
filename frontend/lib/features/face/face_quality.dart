import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:face_detection_tflite/face_detection_tflite.dart';

/// Which kind of photo we are checking.
/// front = looking straight at the camera (check-in, and the first registration photo).
/// side  = head turned a little to one side (the 2nd and 3rd registration photos).
enum FaceAngle { front, side }

class FaceCheckResult {
  /// null = the photo is good. Otherwise a short sentence for the user.
  final String? problem;

  /// Head turn (degrees). Used to make sure the two side photos face opposite ways.
  final double yaw;

  const FaceCheckResult({this.problem, this.yaw = 0});
  bool get ok => problem == null;
}

/// Decides if a photo is good enough BEFORE it is turned into numbers.
/// A bad photo (half face, far away, too dark, looking away) gives bad numbers,
/// and bad numbers are how wrong people get in or right people get refused.
///
/// All limits are here, so you can tune them in one place.
class FaceQuality {
  FaceQuality._();

  static const double minDetectorScore = 0.75; // is it really a face?
  static const double edgeMargin = 0.03; // face must stay 3% away from every edge
  static const double minWidthFraction = 0.30; // face width / photo width (too far below this)
  static const double maxWidthFraction = 0.80; // (too close above this)
  static const double maxCenterOffsetX = 0.18; // face centre may be this far from the middle
  static const double maxCenterOffsetY = 0.20;
  static const double minEyeOpen = 0.4; // 0 = closed, 1 = open
  static const double maxFrontYaw = 15; // degrees
  static const double minSideYaw = 12;
  static const double maxSideYaw = 55;
  static const double maxPitch = 25;
  static const double maxRoll = 20;
  static const double minBrightness = 55; // 0 = black, 255 = white
  static const double maxBrightness = 225;

  static Future<FaceCheckResult> check(Face face, Uint8List bytes, FaceAngle angle) async {
    final image = await _decode(bytes);
    try {
      // --- size of the photo (the detector may count it rotated, so double-check) ---
      double w = image.width.toDouble();
      double h = image.height.toDouble();
      final box = face.boundingBox;
      final frac = face.widthFraction;
      if ((box.width / w - frac).abs() > 0.05 && (box.width / h - frac).abs() < 0.05) {
        final t = w;
        w = h;
        h = t;
      }

      final yaw = face.headEulerAngleY ?? 0;
      final pitch = face.headEulerAngleX ?? 0;
      final roll = face.headEulerAngleZ ?? 0;

      FaceCheckResult bad(String text) => FaceCheckResult(problem: text, yaw: yaw);

      // 1. Is it clearly a face?
      if (face.score < minDetectorScore) {
        return bad('Your face is not clear. Look straight at the camera.');
      }

      // 2. Is the whole face inside the photo?
      final left = box.topLeft.x;
      final top = box.topLeft.y;
      final right = box.bottomRight.x;
      final bottom = box.bottomRight.y;
      if (left < w * edgeMargin ||
          top < h * edgeMargin ||
          right > w * (1 - edgeMargin) ||
          bottom > h * (1 - edgeMargin)) {
        return bad('Keep your whole face inside the frame.');
      }

      // 3. Not too far, not too close.
      if (frac < minWidthFraction) return bad('Move closer to the camera.');
      if (frac > maxWidthFraction) return bad('Move a little back from the camera.');

      // 4. In the middle.
      final cx = box.center.x / w;
      final cy = box.center.y / h;
      if ((cx - 0.5).abs() > maxCenterOffsetX || (cy - 0.5).abs() > maxCenterOffsetY) {
        return bad('Move your face to the middle of the frame.');
      }

      // 5. Eyes open (front photos only; side photos hide one eye).
      if (angle == FaceAngle.front) {
        final l = face.leftEyeOpenProbability;
        final r = face.rightEyeOpenProbability;
        if (l != null && r != null && (l < minEyeOpen || r < minEyeOpen)) {
          return bad('Open your eyes and look at the camera.');
        }
      }

      // 6. Head direction.
      if (angle == FaceAngle.front) {
        if (yaw.abs() > maxFrontYaw) return bad('Look straight at the camera.');
      } else {
        if (yaw.abs() < minSideYaw) return bad('Turn your head a little more to the side.');
        if (yaw.abs() > maxSideYaw) return bad('Do not turn so far. Keep your face visible.');
      }
      if (pitch.abs() > maxPitch) return bad('Keep your head level. Do not look up or down.');
      if (roll.abs() > maxRoll) return bad('Do not tilt your head.');

      // 7. Light.
      final brightness = await _averageBrightness(image);
      if (brightness != null) {
        if (brightness < minBrightness) return bad('It is too dark. Find more light.');
        if (brightness > maxBrightness) return bad('It is too bright. Avoid strong light.');
      }

      return FaceCheckResult(yaw: yaw);
    } finally {
      image.dispose();
    }
  }

  static Future<ui.Image> _decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Average light of the whole photo, checking only every 16th pixel (fast).
  static Future<double?> _averageBrightness(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    double sum = 0;
    int count = 0;
    for (int y = 0; y < image.height; y += 16) {
      for (int x = 0; x < image.width; x += 16) {
        final i = (y * image.width + x) * 4;
        sum += 0.299 * data.getUint8(i) + 0.587 * data.getUint8(i + 1) + 0.114 * data.getUint8(i + 2);
        count++;
      }
    }
    return count == 0 ? null : sum / count;
  }
}