// leave_request_model.dart
class LeaveRequestModel {
  final int id;
  final int userId;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String? reason;
  final String status; // pending, approved, rejected

  LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.dateFrom,
    required this.dateTo,
    this.reason,
    required this.status,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) => LeaveRequestModel(
        id: json['id'],
        userId: json['user_id'],
        dateFrom: DateTime.parse(json['date_from']),
        dateTo: DateTime.parse(json['date_to']),
        reason: json['reason'],
        status: json['status'],
      );

  Map<String, dynamic> toJson() => {
        'date_from': dateFrom.toIso8601String().split('T').first,
        'date_to': dateTo.toIso8601String().split('T').first,
        'reason': reason,
      };
}