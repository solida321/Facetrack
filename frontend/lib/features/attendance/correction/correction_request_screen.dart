import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/auth_controller.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/correction_api.dart';
import '../../../data/models/correction_request_model.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/bloom_card.dart';
import '../../../widgets/filter_chips.dart';
import '../../../widgets/primary_button.dart';

class CorrectionRequestScreen extends StatefulWidget {
  final int attendanceRecordId;

  /// The day of the shift. The check-out time you pick is placed on this day.
  final DateTime? attendanceDate;

  /// Show the "real check-out time" field (used when you forgot to check out).
  final bool askCheckOut;

  /// What the record says now: 'present', 'late' or 'absent'.
  /// Late and absent records let you say what the status should be.
  final String? currentStatus;

  /// The recorded check-in time (null for an absent record).
  final DateTime? checkInTime;

  const CorrectionRequestScreen({
    super.key,
    required this.attendanceRecordId,
    this.attendanceDate,
    this.askCheckOut = false,
    this.currentStatus,
    this.checkInTime,
  });

  @override
  State<CorrectionRequestScreen> createState() => _CorrectionRequestScreenState();
}

class _CorrectionRequestScreenState extends State<CorrectionRequestScreen> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  TimeOfDay? _checkOut;
  TimeOfDay? _checkIn;
  String? _wantedStatus; // present | late, chosen by the employee

  // Late -> can ask for Present. Absent -> can ask for Present or Late.
  List<String> get _statusOptions {
    switch (widget.currentStatus) {
      case 'late':
        return ['present'];
      case 'absent':
        return ['present', 'late'];
      default:
        return [];
    }
  }

  // An absent record has no check-in, so we also ask when they really arrived.
  bool get _askCheckIn => widget.currentStatus == 'absent' && _wantedStatus != null;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickCheckOut() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _checkOut ?? const TimeOfDay(hour: 17, minute: 0),
    );
    if (picked != null) setState(() => _checkOut = picked);
  }

  Future<void> _pickCheckIn() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _checkIn ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _checkIn = picked);
  }

  DateTime _on(DateTime day, TimeOfDay t) => DateTime(day.year, day.month, day.day, t.hour, t.minute);

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a reason.')),
      );
      return;
    }
    if (_statusOptions.isNotEmpty && _wantedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose what your record should be.')),
      );
      return;
    }
    if (_askCheckIn && _checkIn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose the time you really arrived.')),
      );
      return;
    }
    if (widget.askCheckOut && _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose your real check-out time.')),
      );
      return;
    }

    final day = widget.attendanceDate ?? DateTime.now();
    DateTime? checkInTime;
    if (_askCheckIn && _checkIn != null) checkInTime = _on(day, _checkIn!);
    DateTime? checkOutTime;
    if (_checkOut != null) checkOutTime = _on(day, _checkOut!);

    // The check-out must come after the check-in (the recorded one or the new one).
    final inForCompare = checkInTime ?? widget.checkInTime;
    if (checkOutTime != null && inForCompare != null && !checkOutTime.isAfter(inForCompare)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-out must be after check-in.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final correction = CorrectionRequestModel(
        id: 0,
        attendanceRecordId: widget.attendanceRecordId,
        requestedStatus: _wantedStatus,
        requestedCheckInTime: checkInTime,
        requestedCheckOutTime: checkOutTime,
        reason: _reasonController.text.trim(),
        status: 'pending',
      );
      await CorrectionApi.submit(correction, userId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e, fallback: 'Failed to submit correction'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Dispute record', style: AppTextStyles.heading),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_statusOptions.isNotEmpty) ...[
                Text('What should it be?', style: AppTextStyles.label),
                const SizedBox(height: 8),
                AppFilterChips(
                  labels: [for (final o in _statusOptions) o == 'present' ? 'Present' : 'Late'],
                  selected: _statusOptions.indexOf(_wantedStatus ?? ''),
                  onSelected: (i) => setState(() => _wantedStatus = _statusOptions[i]),
                ),
                const SizedBox(height: 16),
              ],
              if (_askCheckIn) ...[
                Text('Time you really arrived', style: AppTextStyles.label),
                const SizedBox(height: 6),
                BloomCard(
                  onTap: _pickCheckIn,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.login_rounded, size: 20, color: AppColors.primaryDeep),
                      const SizedBox(width: 10),
                      Text(
                        _checkIn == null ? 'Choose time' : _checkIn!.format(context),
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.askCheckOut) ...[
                Text('Real check-out time', style: AppTextStyles.label),
                const SizedBox(height: 6),
                BloomCard(
                  onTap: _pickCheckOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 20, color: AppColors.primaryDeep),
                      const SizedBox(width: 10),
                      Text(
                        _checkOut == null ? 'Choose time' : _checkOut!.format(context),
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              AppTextField(
                label: 'Reason',
                controller: _reasonController,
                maxLines: 4,
                hint: widget.askCheckOut
                    ? 'e.g. I forgot to check out'
                    : 'e.g. Scan failed but I was on-site',
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Submit correction',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}