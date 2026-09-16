import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/jalali_calendar.dart' as jc;
import '../../utils/persian_numbers.dart';
import '../../widgets/jalali_calendar.dart';
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

  @override
  void initState() {
    super.initState();
    final today = jc.JalaliDate.today();
    _viewYear = today.year;
    _viewMonth = today.month;
    _loadDraft();
  }

  void _loadDraft() {
    final state = context.read<AppState>();
    final activePlan = state.activePlanForClient(widget.clientId);
    if (activePlan == null || activePlan.startDate == null) return;

    final start = jc.JalaliDate.tryParse(activePlan.startDate!);
    if (start == null) return;

    final startJdn = start.toJdn();
    final template = state.templateById(activePlan.templateId);
    final duration = template?.days ?? activePlan.days;
    final endJdn = startJdn + duration - 1;

    for (final rec in state.attendanceForClient(widget.clientId)) {
      final recDate = jc.JalaliDate.tryParse(rec.date);
      if (recDate == null) continue;
      final recJdn = recDate.toJdn();
      if (recJdn < startJdn || recJdn > endJdn) continue;
      _draftAttendance[rec.date] = rec.status;
    }
  }

  Map<String, int> _buildCounts() {
    final map = <String, int>{};
    for (final entry in _draftAttendance.entries) {
      if (entry.value == 'present') {
        map[entry.key] = 1;
      }
    }
    return map;
  }

  Map<String, int> _buildAbsentCounts() {
    final map = <String, int>{};
    for (final entry in _draftAttendance.entries) {
      if (entry.value == 'absent') {
        map[entry.key] = 1;
      }
    }
    return map;
  }

  void _toggleDay(String date) {
    final normalized = faToEn(date);
    final parts = normalized.split('/');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        final today = jc.JalaliDate.today();
        if (year > today.year ||
            (year == today.year && month > today.month) ||
            (year == today.year && month == today.month && day > today.day)) {
          return;
        }
      }
    }

    setState(() {
      _selectedDate = date;
      final current = _draftAttendance[date] ?? '';
      if (current == 'present') {
        _draftAttendance[date] = 'absent';
      } else if (current == 'absent') {
        _draftAttendance.remove(date);
      } else {
        _draftAttendance[date] = 'present';
      }
    });
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final dateSessions = <String, int>{};
    for (final entry in _draftAttendance.entries) {
      dateSessions[entry.key] = entry.value == 'present' ? 1 : 0;
    }
    await state.replaceAttendance(widget.clientId, dateSessions);
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

    final presentCounts = _buildCounts();
    final absentCounts = _buildAbsentCounts();

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
          JalaliCalendar(
            year: _viewYear,
            month: _viewMonth,
            selectedDate: _selectedDate,
            presentCounts: presentCounts,
            absentCounts: absentCounts,
            showLegend: true,
            onPrevMonth: _prevMonth,
            onNextMonth: _nextMonth,
            onDayTap: _toggleDay,
          ),
          SizedBox(height: 14),

          // Selected Date Info
          if (_selectedDate != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              alignment: Alignment.center,
              child: Text(
                '$_selectedDate — ${_draftAttendance[_selectedDate] == null ? 'خالی' : _draftAttendance[_selectedDate] == 'present' ? 'حاضر' : 'غایب'}',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _draftAttendance[_selectedDate] == null
                      ? AppTokens.onSurfaceVar
                      : _draftAttendance[_selectedDate] == 'present'
                          ? AppTokens.success
                          : AppTokens.error,
                ),
              ),
            ),

          SizedBox(height: 24),

          if (_draftAttendance.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _draftAttendance.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTokens.onSurfaceVar,
                  side: BorderSide(color: AppTokens.outlineVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rLg)),
                  textStyle: TextStyle(fontFamily: 'Vazir', fontSize: 14, fontWeight: FontWeight.w700),
                ),
                child: Text('بازگرداندن تغییرات'),
              ),
            ),

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
