import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/network/api_error.dart';
import '../../core/network/notification_api.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/notification_model.dart';
import 'notification_bell.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final items = await NotificationApi.getByUser(userId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
      UnreadCount.value.value = items.where((n) => !n.isRead).length;
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// Tap = mark as read.
  /// The dot turns grey immediately (so the screen feels instant), then we
  /// tell the server. If the server says no, we put the dot back.
  Future<void> _markRead(int index) async {
    final item = _items[index];
    if (item.isRead) return;

    setState(() => _items[index] = item.copyWith(isRead: true));
    UnreadCount.value.value = _items.where((n) => !n.isRead).length;

    try {
      await NotificationApi.markRead(item.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _items[index] = item); // undo
      UnreadCount.value.value = _items.where((n) => !n.isRead).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e, fallback: 'Could not mark as read.'))),
      );
    }
  }

  Future<void> _markAllRead() async {
    final old = List<NotificationModel>.from(_items);
    setState(() => _items = _items.map((n) => n.copyWith(isRead: true)).toList());
    UnreadCount.value.value = 0;
    try {
      await NotificationApi.markAllRead();
    } catch (e) {
      if (!mounted) return;
      setState(() => _items = old); // undo
      UnreadCount.value.value = old.where((n) => !n.isRead).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e, fallback: 'Could not mark all as read.'))),
      );
    }
  }

  String _when(DateTime dt) => '${DateFormatter.date(dt)} · ${DateFormatter.time(dt)}';

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          unread > 0 ? 'Notifications ($unread new)' : 'Notifications',
          style: AppTextStyles.heading,
        ),
        actions: [
          if (unread > 0)
            TextButton(onPressed: _markAllRead, child: const Text('Read all')),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: _items.isEmpty
                  // A scrollable even when empty, so pull-to-refresh still works.
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(child: Text('No notifications yet.', style: AppTextStyles.bodySoft)),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final n = _items[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _markRead(i),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: n.isRead ? Colors.transparent : AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 5),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: n.isRead ? AppColors.line : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.title,
                                          style: TextStyle(
                                            fontFamily: 'Sora',
                                            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(n.message, style: AppTextStyles.bodySoft),
                                        const SizedBox(height: 4),
                                        Text(_when(n.createdAt), style: AppTextStyles.label),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}