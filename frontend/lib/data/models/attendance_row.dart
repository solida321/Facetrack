import '../../core/utils/date_formatter.dart';
import 'attendance_record_model.dart';
import 'group_model.dart';
import 'schedule_model.dart';
import 'user_model.dart';

/// One attendance record joined with the employee, team and shift,
/// so the dashboard cards and the CSV export read from the same place.
class AttendanceRow {
  final AttendanceRecordModel record;
  final int employeeId;
  final String name;
  final String email;
  final String team;
  final String shift;

  AttendanceRow({
    required this.record,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.team,
    required this.shift,
  });

  DateTime get date => record.attendanceDate;

  String get checkIn =>
      record.checkInTime == null ? '—' : DateFormatter.time(record.checkInTime!);

  String get checkInStatus {
    switch (record.status) {
      case 'present':
        return 'Present';
      case 'late':
        return 'Late';
      case 'absent':
        return 'Absent';
      default:
        return record.status ?? '—';
    }
  }

  String get checkOut =>
      record.checkOutTime == null ? '—' : DateFormatter.time(record.checkOutTime!);

  /// On time, Early leave, Missing, Not yet (still working) or — (never came).
  String get checkOutStatus {
    if (record.status == 'absent') return '—';
    if (record.missingCheckout) return 'Missing';
    if (record.leftEarly) return 'Early leave';
    if (record.checkOutTime != null) return 'On time';
    if (record.checkInTime != null) return 'Not yet';
    return '—';
  }

  static List<AttendanceRow> build({
    required List<AttendanceRecordModel> records,
    required List<UserModel> users,
    required List<GroupModel> groups,
    required List<ScheduleModel> schedules,
  }) {
    final userById = {for (final u in users) u.id: u};
    final groupById = {for (final g in groups) g.id: g};
    final scheduleById = {for (final s in schedules) s.id: s};

    return records.map((r) {
      final u = userById[r.userId];
      final s = scheduleById[r.scheduleId];
      final groupId = u?.groupId ?? s?.groupId;
      return AttendanceRow(
        record: r,
        employeeId: r.userId,
        name: u?.fullName ?? 'User #${r.userId}',
        email: u?.email ?? '',
        team: groupById[groupId]?.name ?? '—',
        shift: s == null
            ? 'Shift #${r.scheduleId}'
            : '${s.sessionName} ${DateFormatter.shiftRange(s.startTime, s.endTime)}',
      );
    }).toList();
  }
}