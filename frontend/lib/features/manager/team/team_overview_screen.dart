import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/network/user_api.dart';
import '../../../data/models/user_model.dart';

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
      final team = allUsers.where((u) => u.groupId == groupId).toList();
      setState(() { _team = team; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: Text('Team', style: AppTextStyles.heading)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _team.isEmpty
              ? Center(child: Text('No team members found.', style: AppTextStyles.bodySoft))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _team.length,
                  separatorBuilder: (_, _) => const Divider(color: AppColors.line, height: 1),
                  itemBuilder: (context, i) {
                    final u = _team[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Text(u.fullName.isNotEmpty ? u.fullName[0] : '?',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                      title: Text(u.fullName, style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(u.email, style: AppTextStyles.bodySoft),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: u.status == 'active' ? AppColors.presentBg : AppColors.lateBg,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(u.status, style: TextStyle(
                          fontSize: 9.5, fontWeight: FontWeight.w700,
                          color: u.status == 'active' ? AppColors.present : AppColors.late,
                        )),
                      ),
                    );
                  },
                ),
    );
  }
}