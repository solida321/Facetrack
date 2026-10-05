// notification_api.dart
import '../../data/models/notification_model.dart';
import 'api_client.dart';

class NotificationApi {
  static Future<List<NotificationModel>> getByUser(int userId) async {
  final res = await ApiClient.dio.get('/notifications/user/$userId');
  return (res.data as List).map((e) => NotificationModel.fromJson(e)).toList();
}


}