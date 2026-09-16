import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart' as shamsi;
import 'package:zahra_trainer/utils/jalali_calendar.dart';

void main() {
  group('JalaliDate.monthDays', () {
    test('months 1-6 return 31 days', () {
      for (final m in List.generate(6, (i) => i + 1)) {
        expect(JalaliDate.monthDays(1404, m), 31);
      }
    });

    test('months 7-11 return 30 days', () {
      for (final m in List.generate(5, (i) => i + 7)) {
        expect(JalaliDate.monthDays(1404, m), 30);
      }
    });

    test('Esfand returns 29 in non-leap year', () {
      // 1404 is not a leap year
      expect(JalaliDate.monthDays(1404, 12), 29);
    });

    test('Esfand returns 30 in leap year', () {
      // 1403 is a leap year
      expect(JalaliDate.monthDays(1403, 12), 30);
    });
  });

  group('JalaliDate.toJdn', () {
    test('returns same value as shamsi.Jalali(...).julianDayNumber', () {
      final date = JalaliDate(1404, 6, 21);
      final expected = shamsi.Jalali(1404, 6, 21).julianDayNumber;
      expect(date.toJdn(), expected);
    });

    test('JDN difference matches calendar day difference', () {
      final start = JalaliDate(1404, 6, 1);
      final end = JalaliDate(1404, 6, 21);
      final diff = end.toJdn() - start.toJdn();
      expect(diff, 20);
    });
  });
}
