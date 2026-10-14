import 'package:flutter/material.dart';

import 'package:face_detection_tflite/face_detection_tflite.dart';
import 'package:provider/provider.dart';
import '../../../widgets/cover_camera_preview.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/face_profile_api.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  final _angles = ['front', 'left', 'right'];
  int _currentAngleIndex = 0;
  bool _isCapturing = false;
  bool _isCameraReady = false;
  String _statusText = '';

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

  Future<void> _captureCurrentAngle() async {
    final auth = context.read<AuthController>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    setState(() { _isCapturing = true; _statusText = 'Capturing...'; });

    FaceDetector? detector;
    try {
      final file = await CameraService.capture();
      final bytes = await file.readAsBytes();

      setState(() => _statusText = 'Detecting face...');
      detector = await FaceDetector.create();
      final faces = await detector.detectFacesFromBytes(bytes, mode: FaceDetectionMode.full);

      if (faces.isEmpty) {
        setState(() { _isCapturing = false; _statusText = 'No face detected — try again'; });
        return;
      }
      if (faces.length > 1) {
        setState(() { _isCapturing = false; _statusText = 'More than one face detected — try again'; });
        return;
      }

      setState(() => _statusText = 'Saving...');
      final embedding = await detector.getFaceEmbedding(faces.first, bytes);
      final angle = _angles[_currentAngleIndex];

      await FaceProfileApi.uploadEmbedding(
        userId: userId,
        angle: angle,
        embedding: embedding,
      );

      if (_currentAngleIndex < _angles.length - 1) {
        setState(() {
          _currentAngleIndex++;
          _isCapturing = false;
          _statusText = '';
        });
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      }
    } catch (e) {
      setState(() { _isCapturing = false; _statusText = 'Failed: $e'; });
    } finally {
      await detector?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Text('Register your face', style: AppTextStyles.heading),
              const SizedBox(height: 6),
              Text(
                'We\'ll capture three angles so matching works reliably.',
                style: AppTextStyles.bodySoft,
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              Container(
                width: 220, height: 270,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 2.5),
                  borderRadius: BorderRadius.circular(140),
                ),
                clipBehavior: Clip.antiAlias,
                child: _isCameraReady
                    ? CoverCameraPreview(controller: CameraService.controller!)
                    : const Center(child: CircularProgressIndicator(color: AppColors.accent)),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_angles.length, (i) {
                  final active = i == _currentAngleIndex;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 9, height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? AppColors.accent : AppColors.line,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Text('Capturing: ${_angles[_currentAngleIndex]}', style: AppTextStyles.bodySoft),
              if (_statusText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(_statusText, style: AppTextStyles.bodySoft, textAlign: TextAlign.center),
              ],

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isCameraReady && !_isCapturing) ? _captureCurrentAngle : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: _isCapturing
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Capture', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, color: AppColors.accentInk)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}