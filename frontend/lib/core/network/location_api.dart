// location_api.dart
import '../../data/models/location_model.dart';
import 'api_client.dart';

class LocationApi {
  static Future<List<LocationModel>> getAll() async {
    final res = await ApiClient.dio.get('/locations/');
    return (res.data as List).map((e) => LocationModel.fromJson(e)).toList();
  }

  static Future<LocationModel> create(LocationModel location) async {
    final res = await ApiClient.dio.post('/locations/', data: location.toJson());
    return LocationModel.fromJson(res.data);
  }
}