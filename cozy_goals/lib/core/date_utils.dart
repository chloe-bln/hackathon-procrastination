import 'package:intl/intl.dart';

class DayKey {
  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  static String today() => _fmt.format(DateTime.now());

  static String fromDate(DateTime date) => _fmt.format(date);

  static DateTime parse(String value) => _fmt.parseStrict(value);

  static bool isBefore(String left, String right) => parse(left).isBefore(parse(right));

  static List<String> daysBetweenExclusiveEnd(String startInclusive, String endExclusive) {
    final start = parse(startInclusive);
    final end = parse(endExclusive);
    final days = <String>[];
    var cursor = start;
    while (cursor.isBefore(end)) {
      days.add(fromDate(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }
}
