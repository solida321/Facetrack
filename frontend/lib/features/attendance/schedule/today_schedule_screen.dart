import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/schedule_api.dart';
import '../../../data/models/schedule_model.dart';
import '../../../widgets/bloom_card.dart';
import '../../face/scan/face_scan_screen.dart';

class TodayScheduleScreen extends StatefulWidget {
  const TodayScheduleScreen({super.key});

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen> {
  List<ScheduleModel> _schedules = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final auth = context.read<AuthController>();
    final groupId = auth.currentUser?.groupId;

    if (groupId == null) {
      setState(() {
        _error = 'You are not assigned to a group yet. Contact your admin.';
        _isLoading = false;
      });
      return;
    }

    try {
      final all = await ScheduleApi.getByGroup(groupId);
      final now = DateTime.now();
      final today =
          now.weekday - 1; // Dart: Mon=1..Sun=7 -> backend: 0=Mon..6=Sun

      final todaysSchedules = all.where((s) {
        if (s.dayOfWeek != null) return s.dayOfWeek == today;
        if (s.specificDate != null) {
          return s.specificDate!.year == now.year &&
              s.specificDate!.month == now.month &&
              s.specificDate!.day == now.day;
        }
        return false;
      }).toList();

      setState(() {
        _schedules = todaysSchedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load your schedule.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Today\'s schedule', style: AppTextStyles.headline),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: AppTextStyles.bodySoft,
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_schedules.isEmpty) {
      return Center(
        child: Text(
          'No shifts scheduled today.',
          style: AppTextStyles.bodySoft,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final s = _schedules[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: BloomCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.startTime.substring(0, 5)} – ${s.endTime.substring(0, 5)}',
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(s.sessionName, style: AppTextStyles.bodySoft),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FaceScanScreen(scheduleId: s.id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Check in',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentInk,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
