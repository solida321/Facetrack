import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/network/notification_api.dart';
import 'notifications_screen.dart';

/// One shared number for the whole app: "how many unread".
/// The bell shows it, and the Notifications screen updates it.
class UnreadCount {
  UnreadCount._();
  static final ValueNotifier<int> value = ValueNotifier<int>(0);

  static Future<void> refresh(int userId) async {
    try {
      value.value = await NotificationApi.unreadCount(userId);
    } catch (_) {
      // Keep the old number if the network fails.
    }
  }
}

/// Bell icon with a red number. Put it in any header.
/// - loads the count when it appears,
/// - checks again every 30 seconds and when the app comes back to the front,
/// - shows a small message when a NEW notification arrives while the app is open.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> with WidgetsBindingObserver {
  Timer? _timer;

  int? get _userId => context.read<AuthController>().currentUser?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check(silent: true));
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check({bool silent = false}) async {
    final id = _userId;
    if (id == null || !mounted) return;
    final before = UnreadCount.value.value;
    await UnreadCount.refresh(id);
    if (!mounted || silent) return;
    if (UnreadCount.value.value > before) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You have a new notification.'),
          action: SnackBarAction(label: 'Open', onPressed: _open),
        ),
      );
    }
  }

  Future<void> _open() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _check(silent: true); // the number may have changed on that screen
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: UnreadCount.value,
      builder: (context, count, _) => IconButton(
        tooltip: 'Notifications',
        onPressed: _open,
        icon: Badge(
          isLabelVisible: count > 0,
          backgroundColor: AppColors.absent,
          label: Text(count > 99 ? '99+' : '$count'),
          child: const Icon(Icons.notifications_none_rounded, color: AppColors.ink),
        ),
      ),
    );
  }
}