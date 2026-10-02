import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'home/admin_dashboard_screen.dart';
import 'users/user_management_screen.dart';
import 'approvals/approvals_screen.dart';
import '../profile/user_profile_screen.dart';
import 'schedules/schedule_management_screen.dart';
import 'groups/group_management_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _tabs = const [
  AdminDashboardScreen(),
  UserManagementScreen(),
  ScheduleManagementScreen(),
  GroupManagementScreen(),
  ApprovalsScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Schedules'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Teams'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check_rounded), label: 'Approvals'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
         
        ],
      ),
    );
  }
}