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

  static Future<LocationModel> update(int locationId, LocationModel location) async {
    final res = await ApiClient.dio.put('/locations/$locationId', data: location.toJson());
    return LocationModel.fromJson(res.data);
  }

  static Future<void> delete(int locationId) async {
    await ApiClient.dio.delete('/locations/$locationId');
  }
}