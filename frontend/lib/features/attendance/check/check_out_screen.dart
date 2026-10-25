import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/services/location_service.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/utils/date_formatter.dart';
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
      if (!mounted) return;
      setState(() => _statusText = 'Checking out...');

      final record = await AttendanceApi.checkOut(
        attendanceRecordId: widget.attendanceRecordId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      setState(() => _result = record);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = _friendlyError(e);
        _isError = true;
      });
    }
  }

  String _friendlyError(Object e) {
    // apiErrorMessage digs the server's explanation out of the response.
    final msg = apiErrorMessage(e, fallback: 'Check-out failed. Please try again.');
    if (msg.contains('Already checked out')) return 'You already checked out for this shift.';
    if (msg.contains('not found')) return 'No check-in found for this shift.';
    if (msg.contains('not checked in')) return 'You have not checked in for this shift yet.';
    if (msg.contains('not your attendance')) return 'This attendance record is not yours.';
    return msg;
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
              if (_isError) ...[
                const SizedBox(height: 20),
                // Without this the user would be stuck on the error screen.
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go back'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmation(AttendanceRecordModel record) {
    final checkOutTime =
        record.checkOutTime != null ? DateFormatter.time(record.checkOutTime!) : '';

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
