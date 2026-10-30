import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'home/manager_home_view.dart';
import '../attendance/schedule/my_schedule_screen.dart';
import 'team/team_overview_screen.dart';
import '../admin/approvals/approvals_screen.dart';
import '../leave/leave_request_screen.dart';
import '../profile/user_profile_screen.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _index = 0;

  final _tabs = const [
    ManagerHomeView(),
    MyScheduleScreen(),
    TeamOverviewScreen(),
    ApprovalsScreen(),
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
        selectedItemColor: AppColors.primaryDeep,
        unselectedItemColor: AppColors.inkSoft,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time_filled_rounded), label: 'Shifts'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Team'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check_rounded), label: 'Approvals'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Leave'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}