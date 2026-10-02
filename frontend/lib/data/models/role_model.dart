class RoleModel {
  final int id;
  final String name;

  RoleModel({
    required this.id,
    required this.name,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
        id: json['id'],
        name: json['name'],
      );
}