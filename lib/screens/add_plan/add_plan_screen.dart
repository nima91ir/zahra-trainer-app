import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/jalali_calendar.dart' as jc;
import '../../utils/persian_numbers.dart';
import '../../widgets/jalali_calendar.dart';
import '../../widgets/settings_sheet.dart';
import '../../widgets/mini_tag.dart';

class AddPlanScreen extends StatefulWidget {
  final int clientId;
  const AddPlanScreen({super.key, required this.clientId});

  @override
  State<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends State<AddPlanScreen> {
  int? _selectedTemplateId;
  late String _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = jc.JalaliDate.today().toString();
  }

  Future<void> _selectDate() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            var viewYear = jc.JalaliDate.today().year;
            var viewMonth = jc.JalaliDate.today().month;
            String? selected;

            return AlertDialog(
              title: Text('تاریخ شروع', style: TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.w800)),
              content: SizedBox(
                width: 320,
                height: 360,
                child: JalaliCalendar(
                  year: viewYear,
                  month: viewMonth,
                  selectedDate: selected,
                  onPrevMonth: () {
                    final next = jc.JalaliDate(viewYear, viewMonth, 1).prevMonth();
                    setState(() {
                      viewYear = next.year;
                      viewMonth = next.month;
                    });
                  },
                  onNextMonth: () {
                    final next = jc.JalaliDate(viewYear, viewMonth, 1).nextMonth();
                    setState(() {
                      viewYear = next.year;
                      viewMonth = next.month;
                    });
                  },
                  onDayTap: (dateStr) {
                    selected = dateStr;
                    Navigator.pop(ctx, dateStr);
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('لغو', style: TextStyle(fontFamily: 'Vazir'))),
              ],
            );
          },
        );
      },
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _savePlan() async {
    if (_selectedTemplateId == null) return;
    final state = context.read<AppState>();
    final nav = Navigator.of(context);

    await state.addPlan(
      clientId: widget.clientId,
      templateId: _selectedTemplateId!,
      startDate: _selectedDate,
    );

    if (mounted) {
      final hasActivePlan = state.activePlanForClient(widget.clientId) != null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasActivePlan ? 'به صف اضافه شد' : 'برنامه فعال شد',
            style: TextStyle(fontFamily: 'Vazir'),
          ),
        ),
      );
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activePlan = state.activePlanForClient(widget.clientId);

    return Scaffold(
      appBar: AppBar(
        title: Text('افزودن برنامه'),
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
          // Queue Warning
          if (activePlan != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTokens.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTokens.rMd),
              ),
              child: Text(
                'ℹ️ این کلاینت برنامه فعال دارد. این برنامه جدید به صف اضافه می‌شود.',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.primaryDark,
                  height: 1.7,
                ),
              ),
            ),
            SizedBox(height: 16),
          ],

          // Template Picker
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'انتخاب قالب',
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTokens.onSurface,
              ),
            ),
          ),
          SizedBox(height: 10),
          if (state.templates.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.rMd),
                border: Border.all(color: AppTokens.outlineVariant),
              ),
              child: Column(
                children: [
                  Text(
                    'هنوز قالبی نساخته‌ای.',
                    style: TextStyle(fontFamily: 'Vazir', fontSize: 13, color: AppTokens.onSurfaceVar),
                  ),
                  SizedBox(height: 14),
                ],
              ),
            )
          else
            ...state.templates.map((t) {
              final isSelected = _selectedTemplateId == t.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedTemplateId = t.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTokens.surface,
                    borderRadius: BorderRadius.circular(AppTokens.rMd),
                    border: Border.all(
                      color: isSelected ? AppTokens.primary : AppTokens.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppTokens.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.fitness_center, color: AppTokens.primary, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name,
                              style: TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTokens.onSurface,
                              ),
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                MiniTag(text: '${fa(t.sessions)} جلسه'),
                                SizedBox(width: 6),
                                MiniTag(text: '${fa(t.days)} روز'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          SizedBox(height: 16),

          // Date Picker
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'تاریخ شروع',
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTokens.onSurface,
              ),
            ),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.rMd),
                border: Border.all(color: AppTokens.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate.isEmpty ? 'انتخاب تاریخ' : _selectedDate,
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.onSurface,
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 18, color: AppTokens.onSurfaceVar),
                ],
              ),
            ),
          ),

          SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _selectedTemplateId != null ? _savePlan : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.rLg),
                ),
                textStyle: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text('ایجاد برنامه'),
            ),
          ),
        ],
      ),
    );
  }
}
