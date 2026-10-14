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
  });

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
      );
}