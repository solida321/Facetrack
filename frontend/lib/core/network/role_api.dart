import '../../data/models/role_model.dart';
import 'api_client.dart';

class RoleApi {
  static Future<List<RoleModel>> getAll() async {
    final res = await ApiClient.dio.get('/roles/');
    return (res.data as List).map((e) => RoleModel.fromJson(e)).toList();
  }
}