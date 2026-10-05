import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/network/leave_api.dart';
import '../../data/models/leave_request_model.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  List<LeaveRequestModel> _myLeaves = [];

  @override
  void initState() {
    super.initState();
    _loadMyLeaves();
  }

  Future<void> _loadMyLeaves() async {
    final auth = context.read<AuthController>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;
    try {
      final leaves = await LeaveApi.getMine(userId);
      setState(() => _myLeaves = leaves);
    } catch (_) {}
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_dateFrom == null || _dateTo == null) return;
    final auth = context.read<AuthController>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSubmitting = true);
    try {
      final leave = LeaveRequestModel(
        id: 0,
        userId: userId,
        dateFrom: _dateFrom!,
        dateTo: _dateTo!,
        reason: _reasonController.text.trim(),
        status: 'pending',
      );
      await LeaveApi.submit(leave, userId);

      _reasonController.clear();
      setState(() {
        _dateFrom = null;
        _dateTo = null;
        _isSubmitting = false;
      });
      _loadMyLeaves();
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit leave request')),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.present;
      case 'rejected':
        return AppColors.absent;
      default:
        return AppColors.late;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'approved':
        return AppColors.presentBg;
      case 'rejected':
        return AppColors.absentBg;
      default:
        return AppColors.lateBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('A little time for you.', style: AppTextStyles.headline),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your leave requests · ${DateTime.now().year}',
              style: AppTextStyles.bodySoft,
            ),
            const SizedBox(height: 16),
            Text('Request leave', style: AppTextStyles.subheading),
            const SizedBox(height: 10),
            _dateField('From', _dateFrom, () => _pickDate(true)),
            const SizedBox(height: 12),
            _dateField('To', _dateTo, () => _pickDate(false)),
            const SizedBox(height: 14),
            Text('Reason', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.panel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit request',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),
            Text('My requests', style: AppTextStyles.label),
            const SizedBox(height: 8),

            if (_myLeaves.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'No leave requests yet.',
                  style: AppTextStyles.bodySoft,
                ),
              )
            else
              ..._myLeaves.map(
                (l) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l.dateFrom.day}/${l.dateFrom.month} – ${l.dateTo.day}/${l.dateTo.month}',
                            style: const TextStyle(
                              fontFamily: 'Sora',
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          if (l.reason != null && l.reason!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(l.reason!, style: AppTextStyles.bodySoft),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusBg(l.status),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          l.status,
                          style: TextStyle(
                            color: _statusColor(l.status),
                            fontWeight: FontWeight.w700,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodySoft),
            Text(
              value == null
                  ? 'Select date'
                  : '${value.day}/${value.month}/${value.year}',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}
