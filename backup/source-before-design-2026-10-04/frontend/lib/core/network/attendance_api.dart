// attendance_api.dart
import '../../data/models/attendance_record_model.dart';
import 'api_client.dart';

class AttendanceApi {
  static Future<AttendanceRecordModel> checkIn({
  required int scheduleId,
  required int userId,
  required double latitude,
  required double longitude,
  required List<double> faceEmbedding,
  String? deviceId,
}) async {
  final res = await ApiClient.dio.post('/attendance/check-in', data: {
    'schedule_id': scheduleId,
    'user_id': userId,
    'latitude': latitude,
    'longitude': longitude,
    'device_id': deviceId,
    'face_embedding': faceEmbedding,
  });
  return AttendanceRecordModel.fromJson(res.data);
}

  static Future<AttendanceRecordModel> checkOut({
    required int attendanceRecordId,
    required double latitude,
    required double longitude,
  }) async {
    final res = await ApiClient.dio.post('/attendance/check-out', data: {
      'attendance_record_id': attendanceRecordId,
      'latitude': latitude,
      'longitude': longitude,
    });
    return AttendanceRecordModel.fromJson(res.data);
  }

  static Future<List<AttendanceRecordModel>> getMyHistory(int userId) async {
    final res = await ApiClient.dio.get('/attendance/user/$userId');
    return (res.data as List).map((e) => AttendanceRecordModel.fromJson(e)).toList();
  }
  static Future<List<AttendanceRecordModel>> getAll() async {
  final res = await ApiClient.dio.get('/attendance/');
  return (res.data as List).map((e) => AttendanceRecordModel.fromJson(e)).toList();
}
}