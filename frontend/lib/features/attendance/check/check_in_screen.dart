import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/services/location_service.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/attendance_record_model.dart';
import 'package:dio/dio.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/info_banner.dart';
class CheckInScreen extends StatefulWidget {
  final int scheduleId;
  final List<double> faceEmbedding;
  const CheckInScreen({super.key, required this.scheduleId, required this.faceEmbedding});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String _statusText = 'Getting your location...';
  bool _isError = false;
  AttendanceRecordModel? _result;

  @override
  void initState() {
    super.initState();
    _runCheckIn();
  }

  Future<void> _runCheckIn() async {
    final auth = context.read<AuthController>();
    final userId = auth.currentUser?.id;

    if (userId == null) {
      setState(() { _statusText = 'You must be logged in to check in.'; _isError = true; });
      return;
    }

    try {
      final position = await LocationService.getCurrentPosition();
      setState(() => _statusText = 'Verifying and checking in...');

      final record = await AttendanceApi.checkIn(
       scheduleId: widget.scheduleId,
       userId: userId,
      latitude: position.latitude,
       longitude: position.longitude,
      faceEmbedding: widget.faceEmbedding,
      );

      setState(() => _result = record);
   } catch (e) {
   setState(() { _statusText = _friendlyError(e); _isError = true; });
   }
  }

  String _friendlyError(Object e) {
  String detail = '';

  if (e is DioException && e.response?.data is Map) {
    detail = (e.response!.data as Map)['detail']?.toString() ?? '';
  }

  final msg = detail.isNotEmpty ? detail : e.toString();

  if (msg.contains('already checked in')) return 'You already checked in for this shift today.';
  if (msg.contains('outside the allowed')) return 'You are outside the allowed check-in area.';
  if (msg.contains('Face verification failed')) return 'Face not recognized. Please try again.';
  if (msg.contains('No registered face')) return 'You have not completed face registration yet.';
  if (msg.contains('Too early')) return 'Too early to check in — please wait until closer to your shift start time.';
  if (msg.contains('permission')) return 'Location permission is needed to check in.';
  return 'Check-in failed. Please try again.';
}
  @override
  Widget build(BuildContext context) {
    if (_result != null) return _buildConfirmation(_result!);

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
                    title: 'Check-in failed',
                    subtitle: _statusText,
                    tone: BannerTone.bad,
                  )
                else
                  Text(_statusText,
                      style: AppTextStyles.body, textAlign: TextAlign.center),
                if (_isError) ...[
                  const SizedBox(height: 24),
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
    final statusColor = record.status == 'late' ? AppColors.late : AppColors.present;
    final statusBg = record.status == 'late' ? AppColors.lateBg : AppColors.presentBg;
    final checkInTime = record.checkInTime != null
        ? DateFormatter.time(record.checkInTime!)
        : '';

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
                      decoration: BoxDecoration(color: statusBg, shape: BoxShape.circle),
                      child: Icon(Icons.check_rounded, color: statusColor, size: 48),
                    ),
                    const SizedBox(height: 22),
                    Text('Checked in', style: AppTextStyles.heading),
                    const SizedBox(height: 6),
                    Text(checkInTime, style: AppTextStyles.bodySoft),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                          color: statusBg, borderRadius: BorderRadius.circular(100)),
                      child: Text(
                        record.status?.toUpperCase() ?? '',
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              PrimaryButton(label: 'Done', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}