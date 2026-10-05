// schedule_model.dart
class ScheduleModel {
  final int id;
  final int groupId;
  final String sessionName;
  final int? dayOfWeek;
  final DateTime? specificDate;
  final String startTime;  // "09:00:00"
  final String endTime;
  final int gracePeriodMinutes;
  final int? locationId;

  ScheduleModel({
    required this.id,
    required this.groupId,
    required this.sessionName,
    this.dayOfWeek,
    this.specificDate,
    required this.startTime,
    required this.endTime,
    required this.gracePeriodMinutes,
    this.locationId,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) => ScheduleModel(
        id: json['id'],
        groupId: json['group_id'],
        sessionName: json['session_name'],
        dayOfWeek: json['day_of_week'],
        specificDate: json['specific_date'] != null ? DateTime.parse(json['specific_date']) : null,
        startTime: json['start_time'],
        endTime: json['end_time'],
        gracePeriodMinutes: json['grace_period_minutes'],
        locationId: json['location_id'],
      );

  Map<String, dynamic> toJson() => {
        'group_id': groupId,
        'session_name': sessionName,
        'day_of_week': dayOfWeek,
        'specific_date': specificDate?.toIso8601String().split('T').first,
        'start_time': startTime,
        'end_time': endTime,
        'grace_period_minutes': gracePeriodMinutes,
        'location_id': locationId,
      };
}