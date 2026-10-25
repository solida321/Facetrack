// attendance_record_model.dart
class AttendanceRecordModel {
  final int id;
  final int scheduleId;
  final int userId;
  final DateTime attendanceDate;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? status; // present, late, absent
  final double? checkInLatitude;
  final double? checkInLongitude;
  final String verificationMethod;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? checkOutStatus; // on_time, early_leave, missing (null = not checked out yet)

  AttendanceRecordModel({
    required this.id,
    required this.scheduleId,
    required this.userId,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.status,
    this.checkInLatitude,
    this.checkInLongitude,
    required this.verificationMethod,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkOutStatus,
  });

  /// Checked out before the shift ended.
  bool get leftEarly => checkOutStatus == 'early_leave';

  /// Never checked out (flagged by the job).
  bool get missingCheckout => checkOutStatus == 'missing';

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) => AttendanceRecordModel(
        id: json['id'],
        scheduleId: json['schedule_id'],
        userId: json['user_id'],
        attendanceDate: DateTime.parse(json['attendance_date']),
        checkInTime: json['check_in_time'] != null ? DateTime.parse(json['check_in_time']).toLocal() : null,
        checkOutTime: json['check_out_time'] != null ? DateTime.parse(json['check_out_time']).toLocal() : null,
        status: json['status'],
        checkInLatitude: json['check_in_latitude']?.toDouble(),
        checkInLongitude: json['check_in_longitude']?.toDouble(),
        verificationMethod: json['verification_method'],
        checkOutLatitude: json['check_out_latitude']?.toDouble(),
        checkOutLongitude: json['check_out_longitude']?.toDouble(),
        checkOutStatus: json['check_out_status'],
      );
}