import 'package:flutter/material.dart';

import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/face/registration/face_register_screen.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/employee/employee_shell.dart';
import '../../features/manager/manager_shell.dart';
import '../../features/admin/admin_shell.dart';
import '../../features/attendance/schedule/today_schedule_screen.dart';



import '../../features/attendance/history/attendance_history_screen.dart';

import '../../features/leave/leave_request_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/user_profile_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String faceRegistration = '/face-registration';
  static const String faceScan = '/face-scan';
  static const String dashboard = '/dashboard';
  static const String employeeShell = '/employee';
  static const String managerShell = '/manager';
  static const String adminShell = '/admin';
  static const String checkIn = '/check-in';
  static const String checkOut = '/check-out';
  static const String todaySchedule = '/today-schedule';
  static const String attendanceHistory = '/attendance-history';
  static const String attendanceDetail = '/attendance-detail';
  static const String correctionRequest = '/correction-request';
  static const String leaveRequest = '/leave-request';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> routes = {
  login: (context) => const LoginScreen(),
  register: (context) => const RegisterScreen(),
  faceRegistration: (context) => const FaceRegistrationScreen(),
  dashboard: (context) => const DashboardScreen(),
  employeeShell: (context) => const EmployeeShell(),
  managerShell: (context) => const ManagerShell(),
  adminShell: (context) => const AdminShell(),
  todaySchedule: (context) => const TodayScheduleScreen(),
  attendanceHistory: (context) => const AttendanceHistoryScreen(),
  leaveRequest: (context) => const LeaveRequestScreen(),
  notifications: (context) => const NotificationsScreen(),
  profile: (context) => const UserProfileScreen(),
};
}