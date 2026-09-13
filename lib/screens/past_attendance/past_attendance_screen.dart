import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/jalali_calendar.dart' as jc;
import '../../utils/persian_numbers.dart';

class PastAttendanceScreen extends StatefulWidget {
  final int clientId;
  const PastAttendanceScreen({super.key, required this.clientId});

  @override
  State<PastAttendanceScreen> createState() =>
      _PastAttendanceScreenState();
}

class _PastAttendanceScreenState extends State<PastAttendanceScreen> {
  late jc.JalaliDate _viewMonth;
  final Map<String, String> _draft = {};

  @override
  void initState() {
    super.initState();
    final today = jc.JalaliDate.today();
    _viewMonth = jc.JalaliDate(today.year, today.month, 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed the draft from the current database state, only once.
    if (_draft.isEmpty) {
      final state = context.read<AppState>();
      for (final rec in state.attendanceForClient(widget.clientId)) {
        _draft[rec.date] = rec.status;
      }
    }
  }

  void _toggleDay(String dateStr) {
    setState(() {
      final current = _draft[dateStr];
      if (current == null) {
        _draft[dateStr] = 'present';
      } else if (current == 'present') {
        _draft[dateStr] = 'absent';
      } else {
        _draft.remove(dateStr);
      }
    });
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final nav = Navigator.of(context);
    await state.replaceAttendance(widget.clientId, _draft);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ذخیره شد',
              style: TextStyle(fontFamily: 'Vazir')),
        ),
      );
      nav.pop();
    }
  }

  String _dateStr(int day) {
    final m = _viewMonth.month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return fa('${_viewMonth.year}/$m/$d');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final client = state.clientById(widget.clientId);
    final activePlan = state.activePlanForClient(widget.clientId);
    final template = activePlan != null
        ? state.templateById(activePlan.templateId)
        : null;

    final today = jc.JalaliDate.today().toString();
    final totalDays =
        jc.JalaliDate.monthDays(_viewMonth.year, _viewMonth.month);
    final firstWeekday = jc.JalaliDate.firstWeekdayOfMonth(
        _viewMonth.year, _viewMonth.month);

    final cells = <Widget>[];
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int d = 1; d <= totalDays; d++) {
      final ds = _dateStr(d);
      final status = _draft[ds];
      final isToday = ds == today;

      cells.add(GestureDetector(
        onTap: () => _toggleDay(ds),
        child: Container(
          decoration: BoxDecoration(
            color: status == 'present'
                ? AppTokens.successSoft
                : status == 'absent'
                    ? AppTokens.errorSoft
                    : (isToday
                        ? AppTokens.primary.withValues(alpha: 0.10)
                        : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: isToday
                ? Border.all(
                    color: AppTokens.primary.withValues(alpha: 0.55),
                    width: 1.5,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fa(d),
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 12.5,
                  fontWeight:
                      status != null ? FontWeight.w900 : FontWeight.w600,
                  color: status == 'present'
                      ? AppTokens.success
                      : status == 'absent'
                          ? AppTokens.error
                          : AppTokens.onSurface,
                ),
              ),
            ],
          ),
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('حضور گذشته'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Plan info card
          if (template != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.rMd),
                border: Border.all(color: AppTokens.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTokens.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.fitness_center,
                        size: 16, color: AppTokens.onSurfaceVar),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fa(activePlan!.remaining)} جلسه از ${fa(template.sessions)} باقی‌مانده',
                          style: const TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 11,
                            color: AppTokens.onSurfaceVar,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Hint
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.rMd),
              border: Border.all(color: AppTokens.outlineVariant),
            ),
            child: const Text(
              'روی هر روز بزن تا وضعیتش عوض شود: حاضر → غایب → خالی',
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTokens.onSurfaceVar,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Calendar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.rLg),
              border: Border.all(color: AppTokens.outlineVariant),
            ),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() {
                        _viewMonth = _viewMonth.prevMonth();
                      }),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${jc.JalaliDate.monthNames[_viewMonth.month - 1]} ${fa(_viewMonth.year)}',
                          style: const TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.onSurface,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() {
                        _viewMonth = _viewMonth.nextMonth();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

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
              ],
            ),
          ),

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('ذخیره و بازگشت'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.rLg),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Vazir',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}