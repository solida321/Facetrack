// group_api.dart
import '../../data/models/group_model.dart';
import 'api_client.dart';

class GroupApi {
  static Future<List<GroupModel>> getAll() async {
    final res = await ApiClient.dio.get('/groups/');
    return (res.data as List).map((e) => GroupModel.fromJson(e)).toList();
  }

  static Future<GroupModel> create(GroupModel group) async {
  final res = await ApiClient.dio.post('/groups/', data: {'name': group.name, 'type': group.type, 'owner_user_id': group.ownerUserId});
  return GroupModel.fromJson(res.data);
}

static Future<GroupModel> update(int groupId, GroupModel group) async {
  final res = await ApiClient.dio.put('/groups/$groupId', data: {'name': group.name, 'type': group.type, 'owner_user_id': group.ownerUserId});
  return GroupModel.fromJson(res.data);
}

static Future<void> delete(int groupId) async {
  await ApiClient.dio.delete('/groups/$groupId');
}
}