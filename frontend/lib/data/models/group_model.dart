// group_model.dart
class GroupModel {
  final int id;
  final String name;
  final String type;
  final int? ownerUserId;

  GroupModel({required this.id, required this.name, required this.type, this.ownerUserId});

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'],
        name: json['name'],
        type: json['type'],
        ownerUserId: json['owner_user_id'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'owner_user_id': ownerUserId,
      };
}