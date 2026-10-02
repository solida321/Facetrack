import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart';

import '../../../core/services/camera_service.dart';

/// Temporary — only to confirm the package works before wiring it into
/// Face Registration / Check-in. Not linked into app_routes.dart.
class FaceEmbeddingTestScreen extends StatefulWidget {
  const FaceEmbeddingTestScreen({super.key});

  @override
  State<FaceEmbeddingTestScreen> createState() => _FaceEmbeddingTestScreenState();
}

class _FaceEmbeddingTestScreenState extends State<FaceEmbeddingTestScreen> {
  bool _isCameraReady = false;
  bool _isProcessing = false;
  String _result = 'Tap the button to test';

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

  Future<void> _runTest() async {
    setState(() {
      _isProcessing = true;
      _result = 'Capturing...';
    });

    FaceDetector? detector;
    try {
      final file = await CameraService.capture();
      final bytes = await File(file.path).readAsBytes();

      setState(() => _result = 'Loading detector...');
      detector = await FaceDetector.create();

      setState(() => _result = 'Detecting face...');
      final faces = await detector.detectFacesFromBytes(bytes, mode: FaceDetectionMode.full);

      if (faces.isEmpty) {
        setState(() => _result = 'No face detected. Try again with better lighting.');
        return;
      }
      if (faces.length > 1) {
        setState(() => _result = 'Detected ${faces.length} faces. Make sure only one face is in frame.');
        return;
      }

      setState(() => _result = 'Face found (score ${faces.first.score.toStringAsFixed(2)}). Getting embedding...');
      final embedding = await detector.getFaceEmbedding(faces.first, bytes);

      setState(() {
        _result = 'Success.\nEmbedding length: ${embedding.length}\n'
            'First 5 values: ${embedding.take(5).map((v) => v.toStringAsFixed(3)).join(", ")}';
      });
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      await detector?.dispose();
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face embedding test')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_isCameraReady)
              SizedBox(
                height: 300,
                child: CameraPreview(CameraService.controller!),
              )
            else
              const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_isCameraReady && !_isProcessing) ? _runTest : null,
              child: _isProcessing
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Capture and test'),
            ),
            const SizedBox(height: 20),
            Text(_result, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}