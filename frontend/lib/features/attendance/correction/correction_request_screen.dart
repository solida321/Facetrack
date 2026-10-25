import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/auth_controller.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/correction_api.dart';
import '../../../data/models/correction_request_model.dart';

class CorrectionRequestScreen extends StatefulWidget {
  final int attendanceRecordId;

  /// The day of the shift. The check-out time you pick is placed on this day.
  final DateTime? attendanceDate;

  /// Show the "real check-out time" field (used when you forgot to check out).
  final bool askCheckOut;

  const CorrectionRequestScreen({
    super.key,
    required this.attendanceRecordId,
    this.attendanceDate,
    this.askCheckOut = false,
  });

  @override
  State<CorrectionRequestScreen> createState() => _CorrectionRequestScreenState();
}

class _CorrectionRequestScreenState extends State<CorrectionRequestScreen> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  TimeOfDay? _checkOut;

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
    if (widget.askCheckOut && _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose your real check-out time.')),
      );
      return;
    }

    DateTime? checkOutTime;
    if (_checkOut != null) {
      final day = widget.attendanceDate ?? DateTime.now();
      checkOutTime = DateTime(day.year, day.month, day.day, _checkOut!.hour, _checkOut!.minute);
    }

    setState(() => _isSubmitting = true);
    try {
      final correction = CorrectionRequestModel(
        id: 0,
        attendanceRecordId: widget.attendanceRecordId,
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
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: Text('Dispute record', style: AppTextStyles.heading)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.askCheckOut) ...[
              Text('Real check-out time', style: AppTextStyles.label),
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: _pickCheckOut,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        _checkOut == null ? 'Choose time' : _checkOut!.format(context),
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text('Reason', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.panel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.line)),
                hintText: widget.askCheckOut ? 'e.g. I forgot to check out' : 'e.g. Scan failed but I was on-site',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _isSubmitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit correction', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}