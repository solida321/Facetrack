import '../../data/models/face_profile_model.dart';
import 'api_client.dart';

class FaceProfileApi {
  static Future<FaceProfileModel> uploadEmbedding({
    required int userId,
    required String angle,
    required List<double> embedding,
  }) async {
    final res = await ApiClient.dio.post(
      '/face-profiles/',
      queryParameters: {'user_id': userId},
      data: {
        'angle': angle,
        'embedding': embedding,
      },
    );
    return FaceProfileModel.fromJson(res.data);
  }

  static Future<List<FaceProfileModel>> getByUser(int userId) async {
    final res = await ApiClient.dio.get('/face-profiles/user/$userId');
    return (res.data as List).map((e) => FaceProfileModel.fromJson(e)).toList();
  }
}