import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/services/location_service.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/outline_button.dart';
import '../../../widgets/info_banner.dart';

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: _isError ? AppColors.absentBg : AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: _isError
                      ? const Icon(Icons.error_outline_rounded,
                          color: AppColors.absent, size: 44)
                      : const Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(
                              strokeWidth: 3, color: AppColors.primary),
                        ),
                ),
                const SizedBox(height: 24),
                if (_isError)
                  InfoBanner(
                    icon: Icons.close_rounded,
                    title: 'Check-out failed',
                    subtitle: _statusText,
                    tone: BannerTone.bad,
                  )
                else
                  Text(_statusText,
                      style: AppTextStyles.body, textAlign: TextAlign.center),
                if (_isError) ...[
                  const SizedBox(height: 24),
                  // Without this the user would be stuck on the error screen.
                  PrimaryButton(
                    label: 'Go back',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmation(AttendanceRecordModel record) {
    final checkOutTime =
        record.checkOutTime != null ? DateFormatter.time(record.checkOutTime!) : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                          color: AppColors.primarySoft, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 48),
                    ),
                    const SizedBox(height: 22),
                    Text('Checked out', style: AppTextStyles.heading),
                    const SizedBox(height: 6),
                    Text(checkOutTime, style: AppTextStyles.bodySoft),
                    const SizedBox(height: 4),
                    Text('Session complete', style: AppTextStyles.bodySoft),
                  ],
                ),
              ),
              AppOutlineButton(label: 'Done', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> confirmAndCheckOut(BuildContext context, AttendanceRecordModel record) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Check out now?'),
      content: const Text('This records the end of your shift using your current location.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Check out')),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CheckOutScreen(attendanceRecordId: record.id)),
  );
}