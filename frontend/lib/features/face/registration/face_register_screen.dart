import 'package:flutter/material.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/face_profile_api.dart';
import '../face_camera_view.dart';
import '../face_quality.dart';
import '../../../widgets/info_banner.dart';
import '../../../widgets/primary_button.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  // The 2nd and 3rd photos must be turned to OPPOSITE sides.
  final _angles = ['front', 'left', 'right'];
  final _instructions = const [
    'Look straight at the camera.',
    'Turn your head a little to ONE side.',
    'Now turn your head to the OTHER side.',
  ];

  int _currentAngleIndex = 0;
  bool _isCapturing = false;
  bool _isCameraReady = false;
  bool _hasProblem = false;
  String _statusText = '';
  double? _firstSideYaw; // remembers which way the 2nd photo was turned

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
      _isCapturing = false;
      _hasProblem = true;
      _statusText = text;
    });
  }

  Future<void> _captureCurrentAngle() async {
    final auth = context.read<AuthController>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isCapturing = true;
      _hasProblem = false;
      _statusText = 'Capturing...';
    });

    FaceDetector? detector;
    try {
      final file = await CameraService.capture();
      final bytes = await file.readAsBytes();

      setState(() => _statusText = 'Detecting face...');
      detector = await FaceDetector.create();
      final faces = await detector.detectFacesFromBytes(bytes, mode: FaceDetectionMode.full);

      if (faces.isEmpty) {
        _fail('No face detected. Try again.');
        return;
      }
      if (faces.length > 1) {
        _fail('More than one face detected. Try again.');
        return;
      }

      // Is the photo good enough?
      final isFront = _currentAngleIndex == 0;
      final quality = await FaceQuality.check(
        faces.first,
        bytes,
        isFront ? FaceAngle.front : FaceAngle.side,
      );
      if (!quality.ok) {
        _fail(quality.problem!);
        return;
      }

      // The two side photos must face opposite ways.
      if (_currentAngleIndex == 1) {
        _firstSideYaw = quality.yaw;
      } else if (_currentAngleIndex == 2 && _firstSideYaw != null && quality.yaw * _firstSideYaw! > 0) {
        _fail('Turn to the OTHER side this time.');
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
      // Shows the server's sentence, e.g. "This photo does not look like your earlier photos."
      _fail(apiErrorMessage(e, fallback: 'Something went wrong. Try again.'));
    } finally {
      await detector?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    const stepLabels = ['Front', 'One side', 'Other side'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Register your face', style: AppTextStyles.headline),
              const SizedBox(height: 6),
              Text(
                'We take three photos so matching works reliably. '
                'Keep your whole face inside the oval.',
                style: AppTextStyles.bodySoft,
              ),
              const SizedBox(height: 14),

              Expanded(
                child: Center(
                  child: _isCameraReady
                      ? FaceCameraView(
                          controller: CameraService.controller!,
                          guideColor: _hasProblem ? AppColors.absent : Colors.white,
                          hint: _instructions[_currentAngleIndex],
                        )
                      : const CircularProgressIndicator(color: AppColors.primary),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: List.generate(_angles.length, (i) {
                  final active = i == _currentAngleIndex;
                  final done = i < _currentAngleIndex;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == _angles.length - 1 ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: done ? AppColors.primarySoft : Colors.white,
                        border: Border.all(
                          color: active ? AppColors.primaryDeep : AppColors.line,
                          width: active ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            done ? Icons.check_circle_rounded : Icons.circle_outlined,
                            size: 18,
                            color: (done || active) ? AppColors.primary : AppColors.inkSoft,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            stepLabels[i],
                            style: AppTextStyles.label.copyWith(
                              color: (done || active) ? AppColors.primaryDeep : AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Photo ${_currentAngleIndex + 1} of ${_angles.length}',
                  style: AppTextStyles.bodySoft,
                ),
              ),
              if (_statusText.isNotEmpty) ...[
                const SizedBox(height: 10),
                if (_hasProblem)
                  InfoBanner(
                    icon: Icons.error_outline_rounded,
                    title: _statusText,
                    tone: BannerTone.bad,
                  )
                else
                  Center(
                    child: Text(
                      _statusText,
                      style: AppTextStyles.bodySoft,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],

              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Capture',
                icon: Icons.face_retouching_natural_rounded,
                onPressed: (_isCameraReady && !_isCapturing) ? _captureCurrentAngle : null,
                isLoading: _isCapturing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}