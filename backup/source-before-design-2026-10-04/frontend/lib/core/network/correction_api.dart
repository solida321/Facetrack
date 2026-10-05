// correction_api.dart
import '../../data/models/correction_request_model.dart';
import 'api_client.dart';

class CorrectionApi {
  static Future<CorrectionRequestModel> submit(CorrectionRequestModel correction, int requestedBy) async {
  final res = await ApiClient.dio.post(
    '/correction-requests/',
    queryParameters: {'requested_by': requestedBy},
    data: correction.toJson(),
  );
  return CorrectionRequestModel.fromJson(res.data);


}


static Future<List<CorrectionRequestModel>> getAllCorrections() async {
  final res = await ApiClient.dio.get('/correction-requests/');
  return (res.data as List).map((e) => CorrectionRequestModel.fromJson(e)).toList();
}


static Future<void> review(int correctionId, int reviewerId, String status) async {
  await ApiClient.dio.put(
    '/correction-requests/$correctionId/review',
    queryParameters: {'reviewer_id': reviewerId},
    data: {'status': status},
  );
}

// correction_api.dart
static Future<List<CorrectionRequestModel>> getByGroup(int groupId) async {
  final res = await ApiClient.dio.get('/correction-requests/group/$groupId');
  return (res.data as List).map((e) => CorrectionRequestModel.fromJson(e)).toList();
}
}