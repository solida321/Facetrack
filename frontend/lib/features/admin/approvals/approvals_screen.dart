import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/leave_api.dart';
import '../../../core/network/correction_api.dart';
import '../../../core/network/attendance_api.dart';
import '../../../core/network/schedule_api.dart';
import '../../../core/network/user_api.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/leave_request_model.dart';
import '../../../data/models/correction_request_model.dart';

import 'package:provider/provider.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/bloom_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/outline_button.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/status_pill.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<LeaveRequestModel> _leaves = [];
  final List<CorrectionRequestModel> _corrections = [];
  bool _isLoading = true;

  // Extra facts, so a card can show WHO and WHAT instead of only numbers.
  Map<int, UserModel> _users = {};
  Map<int, AttendanceRecordModel> _records = {};
  Map<int, ScheduleModel> _schedules = {};

  // Cards the user has tapped open. Keys look like 'c12' (correction) or 'l5' (leave).
  final Set<String> _open = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) return;

    try {
      List<LeaveRequestModel> leaves;
      List<CorrectionRequestModel> corrections;

      if (user.role.name == 'admin') {
        leaves = await LeaveApi.getAllLeaves();
        corrections = await CorrectionApi.getAllCorrections();
      } else {
        // manager — scoped to their own group
        final groupId = user.groupId;
        if (groupId == null) {
          setState(() => _isLoading = false);
          return;
        }
        leaves = await LeaveApi.getByGroup(groupId);
        corrections = await CorrectionApi.getByGroup(groupId);
      }

      await _loadExtras(user.role.name == 'admin', user.groupId);
      if (!mounted) return;

      setState(() {
        _leaves
          ..clear()
          ..addAll(leaves.where((l) => l.status == 'pending'));
        _corrections
          ..clear()
          ..addAll(corrections.where((c) => c.status == 'pending'));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Names, attendance records and shifts used to fill the cards.
  /// Each part is optional: if one fails, the card still shows what it has.
  Future<void> _loadExtras(bool isAdmin, int? groupId) async {
    try {
      final users = await UserApi.getAll();
      _users = {for (final u in users) u.id: u};
    } catch (_) {}
    try {
      final records = await AttendanceApi.getAll();
      _records = {for (final r in records) r.id: r};
    } catch (_) {}
    try {
      final List<ScheduleModel> schedules = isAdmin
          ? await ScheduleApi.getAll()
          : (groupId == null ? <ScheduleModel>[] : await ScheduleApi.getByGroup(groupId));
      _schedules = {for (final sc in schedules) sc.id: sc};
    } catch (_) {}
  }

  Future<void> _reviewLeave(int leaveId, String status) async {
    final auth = context.read<AuthController>();
    final reviewerId = auth.currentUser?.id;
    if (reviewerId == null) return;
    await LeaveApi.review(leaveId, reviewerId, status);
    _load();
  }

  Future<void> _reviewCorrection(int correctionId, String status) async {
    final auth = context.read<AuthController>();
    final reviewerId = auth.currentUser?.id;
    if (reviewerId == null) return;
    await CorrectionApi.review(correctionId, reviewerId, status);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('A little clarity.', style: AppTextStyles.headline),
            Text(
              'Review leave and attendance requests',
              style: AppTextStyles.bodySoft,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDeep,
          unselectedLabelColor: AppColors.inkSoft,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w800, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 14),
          tabs: [
            Tab(text: 'Leave (${_leaves.length})'),
            Tab(text: 'Corrections (${_corrections.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _leaves.isEmpty
                    ? const EmptyState(
                        message: 'No pending leave requests.',
                        icon: Icons.task_alt_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _leaves.length,
                        itemBuilder: (context, i) => _leaveTile(_leaves[i]),
                      ),
                _corrections.isEmpty
                    ? const EmptyState(
                        message: 'No pending correction requests.',
                        icon: Icons.task_alt_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _corrections.length,
                        itemBuilder: (context, i) =>
                            _correctionTile(_corrections[i]),
                      ),
              ],
            ),
    );
  }

  // Reject (red outline) and Approve (green) side by side, used by both tiles.
  Widget _decisionButtons({
    required VoidCallback onReject,
    required VoidCallback onApprove,
  }) {
    return Row(
      children: [
        Expanded(
          child: AppOutlineButton(label: 'Reject', danger: true, onPressed: onReject),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PrimaryButton(label: 'Approve', onPressed: onApprove),
        ),
      ],
    );
  }

  String _clock(DateTime? t) => t == null ? '—' : DateFormatter.time(t.toLocal());

  // One line of the detail list: label on the left, value on the right.
  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 118, child: Text(label, style: AppTextStyles.bodySoft)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  StatusPill _recordPill(String? status) {
    switch (status) {
      case 'present':
        return StatusPill.present('Present');
      case 'late':
        return StatusPill.late('Late');
      case 'absent':
        return StatusPill.absent('Absent');
      default:
        return StatusPill.neutral(status ?? '—');
    }
  }

  // Name + small line + arrow. Tapping it opens or closes the details.
  Widget _cardHeader({
    required String name,
    required String subtitle,
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Row(
        children: [
          AppAvatar(name: name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySoft),
              ],
            ),
          ),
          Icon(
            isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: AppColors.inkSoft,
          ),
        ],
      ),
    );
  }

  Widget _leaveTile(LeaveRequestModel leave) {
    final key = 'l${leave.id}';
    final isOpen = _open.contains(key);
    final name = _users[leave.userId]?.fullName ?? 'Employee #${leave.userId}';
    final days = leave.dateTo.difference(leave.dateFrom).inDays + 1;
    final range =
        '${DateFormatter.date(leave.dateFrom)} – ${DateFormatter.date(leave.dateTo)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BloomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              name: name,
              subtitle: 'Leave · $range',
              isOpen: isOpen,
              onTap: () => setState(() => isOpen ? _open.remove(key) : _open.add(key)),
            ),
            if (isOpen) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.line),
              const SizedBox(height: 6),
              _detail('Employee', name),
              if (_users[leave.userId] != null) _detail('Email', _users[leave.userId]!.email),
              _detail('From', DateFormatter.date(leave.dateFrom)),
              _detail('To', DateFormatter.date(leave.dateTo)),
              _detail('Days', '$days'),
              _detail('Reason', (leave.reason ?? '').isEmpty ? '—' : leave.reason!),
            ],
            const SizedBox(height: 14),
            _decisionButtons(
              onReject: () => _reviewLeave(leave.id, 'rejected'),
              onApprove: () => _reviewLeave(leave.id, 'approved'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _correctionTile(CorrectionRequestModel correction) {
    final key = 'c${correction.id}';
    final isOpen = _open.contains(key);
    final record = _records[correction.attendanceRecordId];
    final person = record == null ? null : _users[record.userId];
    final name = person?.fullName ??
        (record == null ? 'Record #${correction.attendanceRecordId}' : 'Employee #${record.userId}');
    final shift = record == null ? null : _schedules[record.scheduleId];
    final dateText = record == null ? '' : DateFormatter.date(record.attendanceDate);
    final asks = correction.requestedCheckOutTime != null
        ? 'Real check-out ${_clock(correction.requestedCheckOutTime)}'
        : (correction.requestedStatus != null
            ? 'Change status to ${correction.requestedStatus}'
            : 'Correction request');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BloomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              name: name,
              subtitle: dateText.isEmpty ? asks : '$dateText · $asks',
              isOpen: isOpen,
              onTap: () => setState(() => isOpen ? _open.remove(key) : _open.add(key)),
            ),
            const SizedBox(height: 10),
            Text(correction.reason,
                maxLines: isOpen ? null : 2,
                overflow: isOpen ? TextOverflow.visible : TextOverflow.ellipsis,
                style: AppTextStyles.bodySoft),
            if (isOpen) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.line),
              const SizedBox(height: 6),
              _detail('Employee', name),
              if (person != null) _detail('Email', person.email),
              if (dateText.isNotEmpty) _detail('Date', dateText),
              if (shift != null)
                _detail('Shift',
                    '${shift.sessionName} · ${shift.startTime.substring(0, 5)} – ${shift.endTime.substring(0, 5)}'),
              if (record != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(width: 118, child: Text('Now recorded', style: AppTextStyles.bodySoft)),
                      _recordPill(record.status),
                    ],
                  ),
                ),
                _detail('Check-in', _clock(record.checkInTime)),
                _detail('Check-out',
                    record.missingCheckout ? 'Missing' : _clock(record.checkOutTime)),
              ],
              if (correction.requestedCheckInTime != null)
                _detail('Asks check-in', _clock(correction.requestedCheckInTime)),
              if (correction.requestedCheckOutTime != null)
                _detail('Asks check-out', _clock(correction.requestedCheckOutTime)),
              if (correction.requestedStatus != null)
                _detail('Asks status', correction.requestedStatus!),
            ],
            const SizedBox(height: 14),
            _decisionButtons(
              onReject: () => _reviewCorrection(correction.id, 'rejected'),
              onApprove: () => _reviewCorrection(correction.id, 'approved'),
            ),
          ],
        ),
      ),
    );
  }
}