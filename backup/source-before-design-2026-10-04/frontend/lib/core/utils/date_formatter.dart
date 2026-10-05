class DateFormatter {
  DateFormatter._();

  static String time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String date(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}