// correction_request_model.dart
class CorrectionRequestModel {
  final int id;
  final int attendanceRecordId;
  final String? requestedStatus;
  final DateTime? requestedCheckInTime;
  final DateTime? requestedCheckOutTime;
  final String reason;
  final String status;

  CorrectionRequestModel({
    required this.id,
    required this.attendanceRecordId,
    this.requestedStatus,
    this.requestedCheckInTime,
    this.requestedCheckOutTime,
    required this.reason,
    required this.status,
  });

  factory CorrectionRequestModel.fromJson(Map<String, dynamic> json) => CorrectionRequestModel(
        id: json['id'],
        attendanceRecordId: json['attendance_record_id'],
        requestedStatus: json['requested_status'],
        requestedCheckInTime: json['requested_check_in_time'] != null
            ? DateTime.parse(json['requested_check_in_time'])
            : null,
        requestedCheckOutTime: json['requested_check_out_time'] != null
            ? DateTime.parse(json['requested_check_out_time'])
            : null,
        reason: json['reason'],
        status: json['status'],
      );

  Map<String, dynamic> toJson() => {
        'attendance_record_id': attendanceRecordId,
        'requested_status': requestedStatus,
        'requested_check_in_time': requestedCheckInTime?.toUtc().toIso8601String(),
        'requested_check_out_time': requestedCheckOutTime?.toUtc().toIso8601String(),
        'reason': reason,
      };
}