import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'home/manager_home_view.dart';
import '../attendance/schedule/today_schedule_screen.dart';
import 'team/team_overview_screen.dart';
import '../leave/leave_request_screen.dart';
import '../profile/user_profile_screen.dart';
import '../admin/approvals/approvals_screen.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _index = 0;

  final _tabs = const [
  ManagerHomeView(),
  TodayScheduleScreen(),
  TeamOverviewScreen(),
  ApprovalsScreen(),        // ← add this
  LeaveRequestScreen(),
  UserProfileScreen(),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.inkSoft,
        backgroundColor: AppColors.panel,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Team'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check_rounded), label: 'Approvals'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Leave'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}