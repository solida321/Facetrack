// schedule_api.dart
import '../../data/models/schedule_model.dart';
import 'api_client.dart';

class ScheduleApi {
  static Future<List<ScheduleModel>> getAll() async {
    final res = await ApiClient.dio.get('/schedules/');
    return (res.data as List).map((e) => ScheduleModel.fromJson(e)).toList();
  }

  static Future<List<ScheduleModel>> getByGroup(int groupId) async {
    final res = await ApiClient.dio.get('/schedules/group/$groupId');
    return (res.data as List).map((e) => ScheduleModel.fromJson(e)).toList();
  }

  static Future<ScheduleModel> create(ScheduleModel schedule) async {
    final res = await ApiClient.dio.post('/schedules/', data: schedule.toJson());
    return ScheduleModel.fromJson(res.data);
  }


static Future<ScheduleModel> update(int scheduleId, ScheduleModel schedule) async {
  final res = await ApiClient.dio.put('/schedules/$scheduleId', data: schedule.toJson());
  return ScheduleModel.fromJson(res.data);
}

static Future<void> delete(int scheduleId) async {
  await ApiClient.dio.delete('/schedules/$scheduleId');
}
}