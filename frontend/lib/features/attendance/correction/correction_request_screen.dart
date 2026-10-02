import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/auth_controller.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/correction_api.dart';
import '../../../data/models/correction_request_model.dart';

class CorrectionRequestScreen extends StatefulWidget {
  final int attendanceRecordId;
  const CorrectionRequestScreen({super.key, required this.attendanceRecordId});

  @override
  State<CorrectionRequestScreen> createState() => _CorrectionRequestScreenState();
}

class _CorrectionRequestScreenState extends State<CorrectionRequestScreen> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
  final auth = context.read<AuthController>();
  final userId = auth.currentUser?.id;
  if (userId == null) return;

  setState(() => _isSubmitting = true);
  try {
    final correction = CorrectionRequestModel(
      id: 0,
      attendanceRecordId: widget.attendanceRecordId,
      reason: _reasonController.text.trim(),
      status: 'pending',
    );
    await CorrectionApi.submit(correction, userId);
    if (mounted) Navigator.pop(context);
  } catch (e) {
    setState(() => _isSubmitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit correction')));
    }
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
            Text('Reason', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.panel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.line)),
                hintText: 'e.g. Scan failed but I was on-site',
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