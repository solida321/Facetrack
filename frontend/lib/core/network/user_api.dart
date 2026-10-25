import '../../data/models/user_model.dart';
import 'api_client.dart';

class UserApi {
  static Future<UserModel> getMe() async {
    final res = await ApiClient.dio.get('/users/me');
    return UserModel.fromJson(res.data);
  }

  static Future<List<UserModel>> getAll() async {
    final res = await ApiClient.dio.get('/users/');
    return (res.data as List).map((e) => UserModel.fromJson(e)).toList();
  }

static Future<UserModel> updateUser(
  int userId, {
  String? status,
  int? roleId,
  int? groupId,
  String? fullName,
  String? phone,
  String? gender,
  int? actorId,
}) async {
  final Map<String, dynamic> data = {};
  if (status != null) data['status'] = status;
  if (roleId != null) data['role_id'] = roleId;
  if (groupId != null) data['group_id'] = groupId;
  if (fullName != null) data['full_name'] = fullName;
  if (phone != null) data['phone'] = phone;
  if (gender != null) data['gender'] = gender;

  final queryParams = actorId != null ? {'actor_id': actorId} : null;
  final res = await ApiClient.dio.put('/users/$userId', data: data, queryParameters: queryParams);
  return UserModel.fromJson(res.data);
}


static Future<UserModel> create({
  required String fullName,
  required String email,
  required String password,
  required int roleId,
  int? groupId,
}) async {
  final res = await ApiClient.dio.post('/users/', data: {
    'full_name': fullName,
    'email': email,
    'password': password,
    'role_id': roleId,
    'group_id': groupId,
  });
  return UserModel.fromJson(res.data);
}

static Future<void> delete(int userId) async {
  await ApiClient.dio.delete('/users/$userId');
}


  static Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    await ApiClient.dio.put('/users/me/password', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }  
}

