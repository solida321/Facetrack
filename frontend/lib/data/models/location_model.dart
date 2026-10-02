// location_model.dart
class LocationModel {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int allowedRadiusMeters;

  LocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.allowedRadiusMeters,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
        id: json['id'],
        name: json['name'],
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        allowedRadiusMeters: json['allowed_radius_meters'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'allowed_radius_meters': allowedRadiusMeters,
      };
}