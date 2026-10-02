import 'role_model.dart';

class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? gender;
  final int? groupId;
  final RoleModel role;
  final String status;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.gender,
    this.groupId,
    required this.role,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        fullName: json['full_name'],
        email: json['email'],
        phone: json['phone'],
        gender: json['gender'],
        groupId: json['group_id'],
        role: RoleModel.fromJson(json['role']),
        status: json['status'],
      );
}