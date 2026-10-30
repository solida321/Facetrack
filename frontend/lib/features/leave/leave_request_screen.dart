import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/network/leave_api.dart';
import '../../data/models/leave_request_model.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/bloom_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_pill.dart';

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
            AppTextField(
              label: 'Reason',
              controller: _reasonController,
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Submit request',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),

            const SizedBox(height: 26),
            Text('My requests', style: AppTextStyles.subheading),
            const SizedBox(height: 10),

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
                (l) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BloomCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: AppColors.primaryDeep,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l.dateFrom.day}/${l.dateFrom.month} – ${l.dateTo.day}/${l.dateTo.month}',
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.ink,
                                ),
                              ),
                              if (l.reason != null && l.reason!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(l.reason!, style: AppTextStyles.bodySoft),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusPill(
                          text: l.status,
                          color: _statusColor(l.status),
                          background: _statusBg(l.status),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return BloomCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 20, color: AppColors.primaryDeep),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodySoft),
          const Spacer(),
          Text(
            value == null
                ? 'Select date'
                : '${value.day}/${value.month}/${value.year}',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}