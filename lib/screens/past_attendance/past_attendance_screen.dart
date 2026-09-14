import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/jalali_calendar.dart' as jc;
import '../../utils/persian_numbers.dart';
import '../../widgets/settings_sheet.dart';

class PastAttendanceScreen extends StatefulWidget {
  final int clientId;
  const PastAttendanceScreen({super.key, required this.clientId});

  @override
  State<PastAttendanceScreen> createState() => _PastAttendanceScreenState();
}

class _PastAttendanceScreenState extends State<PastAttendanceScreen> {
  late int _viewYear;
  late int _viewMonth;
  final Map<String, String> _draftAttendance = {};
  String? _selectedDate;

  static const List<String> _dows = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

  @override
  void initState() {
    super.initState();
    final today = Jalali.now();
    _viewYear = today.year;
    _viewMonth = today.month;
    _loadDraft();
  }

  void _loadDraft() {
    final state = context.read<AppState>();
    final records = state.attendanceForClient(widget.clientId);
    for (final rec in records) {
      _draftAttendance[rec.date] = rec.status;
    }
  }

  void _toggleDay(String date) {
    final normalized = faToEn(date);
    final parts = normalized.split('/');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        final today = Jalali.now();
        if (year > today.year ||
            (year == today.year && month > today.month) ||
            (year == today.year && month == today.month && day > today.day)) {
          return;
        }
      }
    }

    setState(() {
      _selectedDate = date;
      final current = _draftAttendance[date];
      if (current == null) {
        _draftAttendance[date] = 'present';
      } else if (current == 'present') {
        _draftAttendance[date] = 'absent';
      } else {
        _draftAttendance.remove(date);
      }
    });
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    await state.replaceAttendance(widget.clientId, _draftAttendance);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تاریخچه حضور ذخیره شد', style: TextStyle(fontFamily: 'Vazir'))),
      );
      Navigator.pop(context);
    }
  }

  void _prevMonth() {
    setState(() {
      _viewMonth--;
      if (_viewMonth < 1) {
        _viewMonth = 12;
        _viewYear--;
      }
      _selectedDate = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth++;
      if (_viewMonth > 12) {
        _viewMonth = 1;
        _viewYear++;
      }
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final client = state.clientById(widget.clientId);
    final activePlan = state.activePlanForClient(widget.clientId);
    final template = activePlan != null ? state.templateById(activePlan.templateId) : null;

    // Use shamsi_date for accurate calendar math
    final jDate = Jalali(_viewYear, _viewMonth, 1);
    final totalDays = jDate.monthLength;
    final firstWeekDay = jDate.weekDay; // 1=Shanbe, 7=Jomeh
    final leadingEmptyDays = firstWeekDay - 1;
    
    final today = Jalali.now();

    // Get month name from your custom utility for consistency
    final monthName = jc.JalaliDate(_viewYear, _viewMonth, 1).monthName;

    return Scaffold(
      appBar: AppBar(
        title: Text('حضور گذشته'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, size: 22),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Info Card
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
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppTokens.background, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Icon(Icons.fitness_center, size: 16, color: AppTokens.onSurfaceVar),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template?.name ?? 'برنامه فعال',
                        style: TextStyle(fontFamily: 'Vazir', fontSize: 13, fontWeight: FontWeight.w800, color: AppTokens.onSurface),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${fa(client?.bonusSessions ?? 0)} جلسه اضافه موجود',
                        style: TextStyle(fontFamily: 'Vazir', fontSize: 11, color: AppTokens.onSurfaceVar),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),

          // Instruction
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.rMd),
              border: Border.all(color: AppTokens.outlineVariant),
            ),
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontFamily: 'Vazir', fontSize: 12, color: AppTokens.onSurfaceVar, height: 1.7),
                children: [
                  TextSpan(text: 'روی هر روز بزن تا وضعیتش عوض شود: '),
                  TextSpan(text: 'حاضر', style: TextStyle(color: AppTokens.success, fontWeight: FontWeight.w700)),
                  TextSpan(text: ' ← '),
                  TextSpan(text: 'غایب', style: TextStyle(color: AppTokens.error, fontWeight: FontWeight.w700)),
                  TextSpan(text: ' ← '),
                  TextSpan(text: 'خالی', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          SizedBox(height: 14),

          // Calendar Card
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_right, size: 20),
                      onPressed: _prevMonth,
                      color: AppTokens.onSurfaceVar,
                    ),
                    Text(
                      '$monthName ${fa(_viewYear)}',
                      style: TextStyle(fontFamily: 'Vazir', fontSize: 14, fontWeight: FontWeight.w800, color: AppTokens.onSurface),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_left, size: 20),
                      onPressed: _nextMonth,
                      color: AppTokens.onSurfaceVar,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                // DOW Headers
                Row(
                  children: _dows.map((d) => Expanded(
                    child: Center(
                      child: Text(d, style: TextStyle(fontFamily: 'Vazir', fontSize: 10, fontWeight: FontWeight.w700, color: AppTokens.onSurfaceVar.withValues(alpha: 0.7))),
                    ),
                  )).toList(),
                ),
                SizedBox(height: 6),

                // Days Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                  children: [
                    ...List.generate(leadingEmptyDays, (_) => const SizedBox.shrink()),
                    ...List.generate(totalDays, (index) {
                      final day = index + 1;
                      final dateStr = '${fa(_viewYear)}/${fa(_viewMonth.toString().padLeft(2, '0'))}/${fa(day.toString().padLeft(2, '0'))}';
                      final status = _draftAttendance[dateStr];
                      final isToday = today.year == _viewYear && today.month == _viewMonth && today.day == day;
                      final isSelected = _selectedDate == dateStr;

                      return GestureDetector(
                        onTap: () => _toggleDay(dateStr),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppTokens.primary 
                                : isToday 
                                    ? AppTokens.primary.withValues(alpha: 0.14) 
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                fa(day),
                                style: TextStyle(
                                  fontFamily: 'Vazir',
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w900 : (isToday ? FontWeight.w900 : FontWeight.w600),
                                  color: isSelected ? Colors.white : (isToday ? AppTokens.primaryDark : AppTokens.onSurface),
                                ),
                              ),
                              SizedBox(height: 4),
                              if (status != null)
                                Container(
                                  width: 4, height: 4,
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? (status == 'present' ? Colors.white : const Color(0xFFF5C6C6)) 
                                        : (status == 'present' ? AppTokens.success : AppTokens.error),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 14),

          // Selected Date Info
          if (_selectedDate != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              alignment: Alignment.center,
              child: Text(
                '$_selectedDate — ${_draftAttendance[_selectedDate] == 'present' ? 'حاضر' : (_draftAttendance[_selectedDate] == 'absent' ? 'غایب' : 'پاک شد')}',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _draftAttendance[_selectedDate] == 'present' ? AppTokens.success : (_draftAttendance[_selectedDate] == 'absent' ? AppTokens.error : AppTokens.onSurfaceVar),
                ),
              ),
            ),

          SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rLg)),
                textStyle: TextStyle(fontFamily: 'Vazir', fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: Text('ذخیره و بازگشت'),
            ),
          ),
        ],
      ),
    );
  }
}
