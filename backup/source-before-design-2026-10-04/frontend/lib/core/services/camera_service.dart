import 'package:camera/camera.dart';

class CameraService {
  static CameraController? controller;
  static List<CameraDescription> _cameras = [];

  static Future<void> initialize() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    controller = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
    await controller!.initialize();
  }

  static Future<XFile> capture() async {
    if (controller == null || !controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }
    return controller!.takePicture();
  }

  static void dispose() {
    controller?.dispose();
    controller = null;
  }
}