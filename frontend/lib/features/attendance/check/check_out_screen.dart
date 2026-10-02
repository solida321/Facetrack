import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../core/network/attendance_api.dart';
import '../../../data/models/attendance_record_model.dart';

class CheckOutScreen extends StatefulWidget {
  final int attendanceRecordId;
  const CheckOutScreen({super.key, required this.attendanceRecordId});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  String _statusText = 'Getting your location...';
  bool _isError = false;
  AttendanceRecordModel? _result;

  @override
  void initState() {
    super.initState();
    _runCheckOut();
  }

  Future<void> _runCheckOut() async {
    try {
      final position = await LocationService.getCurrentPosition();
      setState(() => _statusText = 'Checking out...');

      final record = await AttendanceApi.checkOut(
        attendanceRecordId: widget.attendanceRecordId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() => _result = record);
    } catch (e) {
      setState(() {
        _statusText = _friendlyError(e);
        _isError = true;
      });
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Already checked out')) return 'You already checked out.';
    if (msg.contains('not found')) return 'No check-in found for today.';
    return 'Check-out failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _buildConfirmation(_result!);
    }

    return Scaffold(
      backgroundColor: AppColors.panel,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isError) const CircularProgressIndicator(color: AppColors.primary),
              if (_isError)
                const Icon(Icons.error_outline_rounded, color: AppColors.absent, size: 40),
              const SizedBox(height: 16),
              Text(_statusText, style: AppTextStyles.body, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmation(AttendanceRecordModel record) {
    final checkOutTime = record.checkOutTime != null
        ? '${record.checkOutTime!.hour.toString().padLeft(2, '0')}:${record.checkOutTime!.minute.toString().padLeft(2, '0')}'
        : '';

    return Scaffold(
      backgroundColor: AppColors.panel,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 66, height: 66,
              decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 18),
            Text('Checked out — $checkOutTime', style: AppTextStyles.heading),
            const SizedBox(height: 8),
            Text('Session complete', style: AppTextStyles.bodySoft),
            const SizedBox(height: 30),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              child: const Text('Done', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}