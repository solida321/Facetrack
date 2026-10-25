import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../network/api_client.dart';

class ExportService {
  static String _d(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// format: 'csv' or 'xlsx'. groupId: null means all teams.
  /// The backend reads the rows from the database and builds the file.
  /// The app then opens the share sheet so the file can be saved or sent.
  static Future<void> exportAttendance({
    required DateTime from,
    required DateTime to,
    required String format,
    int? groupId,
  }) async {
    final params = <String, dynamic>{
      'date_from': _d(from),
      'date_to': _d(to),
      'format': format,
    };
    // Only send group_id when a team is picked. Sending it empty makes the backend answer 422.
    if (groupId != null) {
      params['group_id'] = groupId;
    }

    final res = await ApiClient.dio.get(
      '/reports/attendance',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );

    final dir = await getTemporaryDirectory();
    final name = 'attendance_${_d(from)}_to_${_d(to)}.$format';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(res.data as List<int>);

    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: name));
  }
}