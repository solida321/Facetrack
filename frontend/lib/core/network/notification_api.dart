// notification_api.dart
import '../../data/models/notification_model.dart';
import 'api_client.dart';

class NotificationApi {
  static Future<List<NotificationModel>> getByUser(int userId) async {
    final res = await ApiClient.dio.get('/notifications/user/$userId');
    return (res.data as List).map((e) => NotificationModel.fromJson(e)).toList();
  }

  /// How many unread notifications this user has (small and fast, used by the bell).
  static Future<int> unreadCount(int userId) async {
    final res = await ApiClient.dio.get('/notifications/user/$userId/unread-count');
    return (res.data['count'] as num).toInt();
  }

  /// Tells the server this notification has been read (PUT /notifications/{id}/read).
  static Future<NotificationModel> markRead(int notificationId) async {
    final res = await ApiClient.dio.put('/notifications/$notificationId/read');
    return NotificationModel.fromJson(res.data);
  }

  /// Marks every notification of the logged-in user as read.
  static Future<void> markAllRead() async {
    await ApiClient.dio.put('/notifications/read-all');
  }
}