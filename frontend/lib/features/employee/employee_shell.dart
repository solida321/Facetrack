import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'home/employee_home_view.dart';
import '../attendance/schedule/my_schedule_screen.dart';
import '../leave/leave_request_screen.dart';
import '../profile/user_profile_screen.dart';

class EmployeeShell extends StatefulWidget {
  const EmployeeShell({super.key});

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _index = 0;

  final _tabs = const [
    EmployeeHomeView(),
    MyScheduleScreen(),
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
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time_filled_rounded), label: 'Shifts'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Leave'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}