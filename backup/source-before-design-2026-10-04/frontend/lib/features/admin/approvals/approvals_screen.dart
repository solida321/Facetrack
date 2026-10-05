import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/leave_api.dart';
import '../../../core/network/correction_api.dart';
import '../../../data/models/leave_request_model.dart';
import '../../../data/models/correction_request_model.dart';

import 'package:provider/provider.dart';
import '../../../core/controllers/auth_controller.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<LeaveRequestModel> _leaves = [];
  final List<CorrectionRequestModel> _corrections = [];
  bool _isLoading = true;

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

    setState(() {
      _leaves..clear()..addAll(leaves.where((l) => l.status == 'pending'));
      _corrections..clear()..addAll(corrections.where((c) => c.status == 'pending'));
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
  }
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
        backgroundColor: AppColors.background, elevation: 0,
        title: Text('Approvals', style: AppTextStyles.heading),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.inkSoft,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Leave'), Tab(text: 'Corrections')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _leaves.isEmpty
                    ? Center(child: Text('No pending leave requests.', style: AppTextStyles.bodySoft))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _leaves.length,
                        itemBuilder: (context, i) => _leaveTile(_leaves[i]),
                      ),
                _corrections.isEmpty
                    ? Center(child: Text('No pending correction requests.', style: AppTextStyles.bodySoft))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _corrections.length,
                        itemBuilder: (context, i) => _correctionTile(_corrections[i]),
                      ),
              ],
            ),
    );
  }

  Widget _leaveTile(LeaveRequestModel leave) {
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${leave.dateFrom.day}/${leave.dateFrom.month} – ${leave.dateTo.day}/${leave.dateTo.month}',
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(leave.reason ?? '', style: AppTextStyles.bodySoft),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reviewLeave(leave.id, 'rejected'),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.absent)),
                  child: const Text('Reject', style: TextStyle(color: AppColors.absent)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _reviewLeave(leave.id, 'approved'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.present),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _correctionTile(CorrectionRequestModel correction) {
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Record #${correction.attendanceRecordId}',
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(correction.reason, style: AppTextStyles.bodySoft),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reviewCorrection(correction.id, 'rejected'),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.absent)),
                  child: const Text('Reject', style: TextStyle(color: AppColors.absent)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _reviewCorrection(correction.id, 'approved'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.present),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}