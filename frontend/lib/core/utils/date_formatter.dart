class DateFormatter {
  DateFormatter._();

  /// 12-hour clock with AM / PM, for example 8:05 AM or 5:30 PM.
  static String time(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final suffix = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour12:${dt.minute.toString().padLeft(2, '0')} $suffix';
  }

  /// Turns a server time such as "08:00:00" or "17:30" into "8:00 AM" or "5:30 PM".
  static String clock(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return time(DateTime(2000, 1, 1, h, m));
  }

  /// A shift as text: "8:00 AM – 5:00 PM".
  static String shiftRange(String start, String end) => '${clock(start)} – ${clock(end)}';

  static String date(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}