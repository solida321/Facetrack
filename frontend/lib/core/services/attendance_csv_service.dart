import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/attendance_row.dart';

/// Builds the attendance CSV in the app from the rows on screen,
/// then opens the share sheet (save to Files, Drive, email ...).
class AttendanceCsvService {
  static String _d(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Wrap a value in quotes when it contains a comma, quote or new line.
  static String _cell(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  static String buildCsv(List<AttendanceRow> rows) {
    final lines = <String>[
      'Date,Employee ID,Employee Name,Email,Team,Shift,Check-in,Check-in Status,Check-out,Check-out Status',
    ];
    for (final r in rows) {
      lines.add([
        _d(r.date),
        '${r.employeeId}',
        r.name,
        r.email,
        r.team,
        r.shift,
        r.checkIn,
        r.checkInStatus,
        r.checkOut,
        r.checkOutStatus,
      ].map(_cell).join(','));
    }
    return lines.join('\r\n');
  }

  static Future<void> share(List<AttendanceRow> rows,
      {required DateTime from, required DateTime to}) async {
    // The BOM at the start makes Excel read Khmer / Chinese names correctly.
    final bytes = utf8.encode('﻿${buildCsv(rows)}');
    final dir = await getTemporaryDirectory();
    final name = 'attendance_${_d(from)}_to_${_d(to)}.csv';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: name));
  }
}