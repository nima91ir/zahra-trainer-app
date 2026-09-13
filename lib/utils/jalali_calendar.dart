import 'package:shamsi_date/shamsi_date.dart' as shamsi;
import 'persian_numbers.dart';

/// Immutable Jalali (Shamsi) date.
/// Only year/month/day — no time component.
class JalaliDate {
  final int year;
  final int month;
  final int day;

  const JalaliDate(this.year, this.month, this.day);

  /// Today's Jalali date.
  factory JalaliDate.today() {
    final now = shamsi.Jalali.now();
    return JalaliDate(now.year, now.month, now.day);
  }

  /// Parses a Jalali string like \'۱۴۰۵/۰۶/۲۱\' or \'1405/06/21\'.
  /// Returns null if the string is malformed.
  static JalaliDate? tryParse(String input) {
    final normalized = faToEn(input.trim());
    final parts = normalized.split('/');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12) return null;
    if (d < 1 || d > 31) return null;
    return JalaliDate(y, m, d);
  }

  /// Returns the date as \'۱۴۰۵/۰۶/۲۱\' (Persian digits, zero-padded).
  @override
  String toString() {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return fa('$year/$m/$d');
  }

  JalaliDate copyWith({int? year, int? month, int? day}) {
    return JalaliDate(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is JalaliDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  // ─── Static data ───
  static const List<String> monthNames = [
    'فروردین', 'اردیبهشت', 'خرداد',
    'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر',
    'دی', 'بهمن', 'اسفند',
  ];

  static const List<String> weekdayLetters = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

  /// Number of days in the given Jalali month.
  /// Months 1-6 = 31 days
  /// Months 7-11 = 30 days
  /// Month 12 = 29 days (30 in leap years — we treat as 29 for simplicity)
  static int monthDays(int year, int month) {
    if (month < 1 || month > 12) return 0;
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return 29;
  }

  /// Weekday index of the first day of the given Jalali month.
  /// 0 = Saturday, 1 = Sunday, ..., 6 = Friday
  static int firstWeekdayOfMonth(int year, int month) {
    final jalali = shamsi.Jalali(year, month, 1);
    final shamsiWeekday = jalali.weekDay; // 1 = Saturday, 7 = Friday in shamsi_date
    return shamsiWeekday - 1;
  }

  /// Persian name of the month (e.g., 'شهریور').
  String get monthName => monthNames[month - 1];

  /// Previous month as a new JalaliDate (day clamped to 1).
  JalaliDate prevMonth() {
    if (month == 1) {
      return JalaliDate(year - 1, 12, 1);
    }
    return JalaliDate(year, month - 1, 1);
  }

  /// Next month as a new JalaliDate (day clamped to 1).
  JalaliDate nextMonth() {
    if (month == 12) {
      return JalaliDate(year + 1, 1, 1);
    }
    return JalaliDate(year, month + 1, 1);
  }
}