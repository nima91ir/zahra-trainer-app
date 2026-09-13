import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../utils/jalali_calendar.dart' as jc;
import '../utils/persian_numbers.dart';

/// A tap-to-interact Jalali month calendar.
///
/// Shows a month header (with prev/next arrows), weekday letters, and a
/// 7-column grid of days. Days with attendance records show small dots
/// below the number. Today is highlighted. A selected day is filled.
class JalaliCalendar extends StatelessWidget {
  final int year;
  final int month;
  final String? selectedDate; // Jalali string like '۱۴۰۵/۰۶/۲۱'
  final Map<String, int> presentCounts; // date → count
  final Map<String, int> absentCounts;  // date → count
  final bool showLegend;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<String>? onDayTap;

  const JalaliCalendar({
    super.key,
    required this.year,
    required this.month,
    this.selectedDate,
    this.presentCounts = const {},
    this.absentCounts = const {},
    this.showLegend = true,
    required this.onPrevMonth,
    required this.onNextMonth,
    this.onDayTap,
  });

  String _dateStr(int day) {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return fa('$year/$m/$d');
  }

  @override
  Widget build(BuildContext context) {
    final today = jc.JalaliDate.today().toString();
    final totalDays = jc.JalaliDate.monthDays(year, month);
    final firstWeekday = jc.JalaliDate.firstWeekdayOfMonth(year, month);

    final cells = <Widget>[];

    // Empty leading cells
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    // Day cells
    for (int d = 1; d <= totalDays; d++) {
      final dateStr = _dateStr(d);
      final isToday = dateStr == today;
      final isSelected = dateStr == selectedDate;
      final presentCount = presentCounts[dateStr] ?? 0;
      final absentCount = absentCounts[dateStr] ?? 0;

      cells.add(_DayCell(
        day: d,
        isToday: isToday,
        isSelected: isSelected,
        presentCount: presentCount,
        absentCount: absentCount,
        onTap: onDayTap == null ? null : () => onDayTap!(dateStr),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.rLg),
        border: Border.all(color: AppTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              _NavButton(icon: Icons.chevron_right, onTap: onPrevMonth),
              Expanded(
                child: Center(
                  child: Text(
                    '${jc.JalaliDate.monthNames[month - 1]} ${fa(year)}',
                    style: const TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.onSurface,
                    ),
                  ),
                ),
              ),
              _NavButton(icon: Icons.chevron_left, onTap: onNextMonth),
            ],
          ),
          const SizedBox(height: 12),

          // Weekday letters
          Row(
            children: jc.JalaliDate.weekdayLetters
                .map((l) => Expanded(
                      child: Center(
                        child: Text(
                          l,
                          style: const TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.onSurfaceVar,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),

          // Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            childAspectRatio: 1,
            children: cells,
          ),

          // Legend
          if (showLegend) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: AppTokens.success, label: 'حاضر'),
                const SizedBox(width: 14),
                _LegendDot(color: AppTokens.error, label: 'غایب'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppTokens.background,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: AppTokens.onSurfaceVar),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Vazir',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppTokens.onSurfaceVar,
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final int presentCount;
  final int absentCount;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.presentCount,
    required this.absentCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.transparent;
    Color fg = AppTokens.onSurface;
    FontWeight weight = FontWeight.w600;
    Border? border;

    if (isSelected) {
      bg = AppTokens.primary;
      fg = Colors.white;
      weight = FontWeight.w900;
    } else if (isToday) {
      bg = AppTokens.primary.withValues(alpha: 0.14);
      fg = AppTokens.primaryDark;
      weight = FontWeight.w900;
      border = Border.all(
        color: AppTokens.primary.withValues(alpha: 0.55),
        width: 1.5,
      );
    }

    final dotColor1 =
        isSelected ? Colors.white : AppTokens.success;
    final dotColor2 =
        isSelected ? const Color(0xFFF5C6C6) : AppTokens.error;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              fa(day),
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 12.5,
                fontWeight: weight,
                color: fg,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (presentCount > 0) ...[
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dotColor1,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
                if (absentCount > 0)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dotColor2,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
