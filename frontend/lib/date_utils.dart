const _weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isTomorrow(DateTime date, DateTime now) =>
    isSameDay(date, now.add(const Duration(days: 1)));

String weekdayShort(DateTime date) => _weekdaysShort[date.weekday - 1];

/// Parses a connector's separate date/time strings ("2026-09-26", "23:59") into one
/// DateTime — the mock data always uses this two-field shape.
DateTime parseDateTime(String date, String time) => DateTime.parse('$date $time');

/// "Today 23:59" (urgent) vs "Tue 18:00" (plain) — the rule used throughout
/// page-courses.md and the dashboard tiles.
class DueLabel {
  final String text;
  final bool isToday;

  DueLabel(this.text, this.isToday);
}

DueLabel dueLabel(DateTime due, DateTime now) {
  final hh = due.hour.toString().padLeft(2, '0');
  final mm = due.minute.toString().padLeft(2, '0');
  if (isSameDay(due, now)) {
    return DueLabel('Today $hh:$mm', true);
  }
  return DueLabel('${weekdayShort(due)} $hh:$mm', false);
}
