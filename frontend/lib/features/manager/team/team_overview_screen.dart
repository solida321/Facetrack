import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/user_api.dart';
import '../../../data/models/user_model.dart';
import '../../../widgets/bloom_card.dart';
import '../../../widgets/status_pill.dart';

class TeamOverviewScreen extends StatefulWidget {
  const TeamOverviewScreen({super.key});

  @override
  State<TeamOverviewScreen> createState() => _TeamOverviewScreenState();
}

class _TeamOverviewScreenState extends State<TeamOverviewScreen> {
  List<UserModel> _team = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    final auth = context.read<AuthController>();
    final groupId = auth.currentUser?.groupId;
    if (groupId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final allUsers = await UserApi.getAll();
      final team = allUsers
          .where((u) => u.groupId == groupId && u.role.name == 'employee')
          .toList();
      setState(() {
        _team = team;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
            Text('A team in bloom.', style: AppTextStyles.headline),
            Text('Operations · Team members', style: AppTextStyles.bodySoft),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _team.isEmpty
          ? Center(
              child: Text(
                'No team members found.',
                style: AppTextStyles.bodySoft,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: _team.length,
              itemBuilder: (context, i) {
                final u = _team[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: BloomCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primarySoft,
                          child: Text(
                            u.fullName.isNotEmpty ? u.fullName[0] : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.fullName,
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(u.email, style: AppTextStyles.bodySoft),
                            ],
                          ),
                        ),
                        u.status == 'active'
                            ? StatusPill.present('Active')
                            : StatusPill.neutral(u.status),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
