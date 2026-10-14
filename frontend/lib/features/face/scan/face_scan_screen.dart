import 'package:flutter/material.dart';
import '../../../widgets/cover_camera_preview.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/camera_service.dart';
import '../../attendance/check/check_in_screen.dart';

class FaceScanScreen extends StatefulWidget {
  final int scheduleId;
  const FaceScanScreen({super.key, required this.scheduleId});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  bool _isCameraReady = false;
  bool _isChecking = false;
  String _statusText = 'Align your face in the frame';

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

  Future<void> _captureAndVerify() async {
    setState(() { _isChecking = true; _statusText = 'Checking...'; });

    FaceDetector? detector;
    try {
      final file = await CameraService.capture();
      final bytes = await file.readAsBytes();

      detector = await FaceDetector.create();
      final faces = await detector.detectFacesFromBytes(bytes, mode: FaceDetectionMode.full);

      if (faces.isEmpty) {
        setState(() { _isChecking = false; _statusText = 'No face detected — try again with better lighting'; });
        return;
      }
      if (faces.length > 1) {
        setState(() { _isChecking = false; _statusText = 'More than one face detected — make sure only you are in frame'; });
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
      setState(() { _isChecking = false; _statusText = 'Something went wrong — try again'; });
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
            Text(_statusText, style: AppTextStyles.bodySoft, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 2.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: _isCameraReady
                    ? CoverCameraPreview(controller: CameraService.controller!)
                    : const Center(child: CircularProgressIndicator(color: AppColors.accent)),
              ),
            ),
            const SizedBox(height: 20),
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