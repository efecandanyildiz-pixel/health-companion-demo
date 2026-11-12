/// A space that never becomes a line break, so "6 h 22" stays together.
const _nbsp = ' ';

/// Minutes as "6 h 22", or "48 min" when under an hour.
String formatHm(int minutes) {
  final value = minutes.abs();
  final hours = value ~/ 60;
  final rest = value % 60;
  if (hours == 0) return '$rest${_nbsp}min';
  return '$hours${_nbsp}h$_nbsp${rest.toString().padLeft(2, '0')}';
}

/// Adds thousands separators, for example 8420 becomes "8,420".
String formatThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Minutes after midnight as a 24-hour clock, for example "01:00".
String formatClock(int minutesAfterMidnight) {
  final minutes = minutesAfterMidnight % (24 * 60);
  final hours = (minutes ~/ 60).toString().padLeft(2, '0');
  final rest = (minutes % 60).toString().padLeft(2, '0');
  return '$hours:$rest';
}

String formatClockTime(DateTime time) =>
    formatClock(time.hour * 60 + time.minute);

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _shortMonths = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', //
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC', //
];

/// For example "TUESDAY · 10 NOV".
String formatEyebrowDate(DateTime date) =>
    '${_weekdays[date.weekday - 1].toUpperCase()} · ${date.day} '
    '${_shortMonths[date.month - 1]}';

/// For example "Monday" for [DateTime.monday].
String weekdayName(int weekday) => _weekdays[weekday - 1];

/// First letter of the weekday, for example "T".
String weekdayLetter(DateTime date) => _weekdays[date.weekday - 1][0];
