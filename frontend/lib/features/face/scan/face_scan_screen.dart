import 'package:flutter/material.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/camera_service.dart';
import '../../attendance/check/check_in_screen.dart';
import '../face_camera_view.dart';
import '../face_quality.dart';

class FaceScanScreen extends StatefulWidget {
  final int scheduleId;
  const FaceScanScreen({super.key, required this.scheduleId});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  bool _isCameraReady = false;
  bool _isChecking = false;
  bool _hasProblem = false;
  String _statusText = 'Keep your whole face inside the oval and look straight at the camera';

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    await CameraService.initialize();
    if (mounted) setState(() => _isCameraReady = true);
  }

  @override
  void dispose() {
    CameraService.dispose();
    super.dispose();
  }

  void _fail(String text) {
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _hasProblem = true;
      _statusText = text;
    });
  }

  Future<void> _captureAndVerify() async {
    setState(() {
      _isChecking = true;
      _hasProblem = false;
      _statusText = 'Checking...';
    });

    FaceDetector? detector;
    try {
      final file = await CameraService.capture();
      final bytes = await file.readAsBytes();

      detector = await FaceDetector.create();
      final faces = await detector.detectFacesFromBytes(bytes, mode: FaceDetectionMode.full);

      if (faces.isEmpty) {
        _fail('No face detected. Try again with better lighting.');
        return;
      }
      if (faces.length > 1) {
        _fail('More than one face detected. Make sure only you are in the frame.');
        return;
      }

      // Is the photo good enough? (whole face, size, centre, eyes, direction, light)
      final quality = await FaceQuality.check(faces.first, bytes, FaceAngle.front);
      if (!quality.ok) {
        _fail(quality.problem!);
        return;
      }

      final embedding = await detector.getFaceEmbedding(faces.first, bytes);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CheckInScreen(scheduleId: widget.scheduleId, faceEmbedding: embedding),
          ),
        );
      }
    } catch (e) {
      _fail('Something went wrong. Try again.');
    } finally {
      await detector?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text('Checking in', style: AppTextStyles.heading),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _statusText,
                style: AppTextStyles.bodySoft.copyWith(
                  color: _hasProblem ? AppColors.absent : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _isCameraReady
                      ? FaceCameraView(
                          controller: CameraService.controller!,
                          guideColor: _hasProblem ? AppColors.absent : Colors.white,
                        )
                      : const CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isCameraReady && !_isChecking) ? _captureAndVerify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: _isChecking
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Scan face', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, color: AppColors.accentInk)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}