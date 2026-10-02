// face_profile_model.dart
class FaceProfileModel {
  final int id;
  final int userId;
  final String angle; // front, left, right
  final double? qualityScore;

  FaceProfileModel({
    required this.id,
    required this.userId,
    required this.angle,
    this.qualityScore,
  });

  factory FaceProfileModel.fromJson(Map<String, dynamic> json) => FaceProfileModel(
        id: json['id'],
        userId: json['user_id'],
        angle: json['angle'],
        qualityScore: json['quality_score']?.toDouble(),
      );
}