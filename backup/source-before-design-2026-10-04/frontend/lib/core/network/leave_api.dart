// leave_api.dart
import '../../data/models/leave_request_model.dart';
import 'api_client.dart';

class LeaveApi {
  static Future<LeaveRequestModel> submit(LeaveRequestModel leave, int userId) async {
  final res = await ApiClient.dio.post(
    '/leave-requests/',
    queryParameters: {'user_id': userId},
    data: leave.toJson(),
  );
  return LeaveRequestModel.fromJson(res.data);
}

static Future<List<LeaveRequestModel>> getMine(int userId) async {
  final res = await ApiClient.dio.get('/leave-requests/user/$userId');
  return (res.data as List).map((e) => LeaveRequestModel.fromJson(e)).toList();
}

static Future<List<LeaveRequestModel>> getAllLeaves() async {
  final res = await ApiClient.dio.get('/leave-requests/');
  return (res.data as List).map((e) => LeaveRequestModel.fromJson(e)).toList();
}

static Future<void> review(int leaveId, int reviewerId, String status) async {
  await ApiClient.dio.put(
    '/leave-requests/$leaveId/review',
    queryParameters: {'reviewer_id': reviewerId},
    data: {'status': status},
  );
}

// leave_api.dart
static Future<List<LeaveRequestModel>> getByGroup(int groupId) async {
  final res = await ApiClient.dio.get('/leave-requests/group/$groupId');
  return (res.data as List).map((e) => LeaveRequestModel.fromJson(e)).toList();
}


}