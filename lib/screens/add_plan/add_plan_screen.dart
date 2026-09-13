import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/plan_template.dart';
import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/jalali_calendar.dart' as jc;
import '../../utils/persian_numbers.dart';

class AddPlanScreen extends StatefulWidget {
  final int clientId;
  const AddPlanScreen({super.key, required this.clientId});

  @override
  State<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends State<AddPlanScreen> {
  int? _selectedTemplateId;
  late jc.JalaliDate _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = jc.JalaliDate.today();
  }

  Future<void> _pickDate() async {
    final picked = await showDialog<jc.JalaliDate>(
      context: context,
      builder: (_) => _JalaliDatePickerDialog(initial: _selectedDate),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (_selectedTemplateId == null) return;
    final state = context.read<AppState>();
    final nav = Navigator.of(context);

    await state.addPlan(
      clientId: widget.clientId,
      templateId: _selectedTemplateId!,
      startDate: _selectedDate.toString(),
    );

    if (mounted) {
      final active = state.activePlanForClient(widget.clientId);
      final queued = state.queuedPlansForClient(widget.clientId);
      final wasQueued = active != null && queued.isNotEmpty;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasQueued ? 'به صف اضافه شد' : 'برنامه فعال شد',
            style: const TextStyle(fontFamily: 'Vazir'),
          ),
        ),
      );
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasActive = state.activePlanForClient(widget.clientId) != null;

    return Scaffold(
      appBar: AppBar(title: const Text('افزودن برنامه')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (hasActive) ...[
            _QueueNotice(),
            const SizedBox(height: 16),
          ],
          const Padding(
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
          const SizedBox(height: 10),
          if (state.templates.isEmpty)
            _NoTemplatesNotice()
          else
            ...state.templates.map((t) => _TemplateOption(
                  template: t,
                  selected: _selectedTemplateId == t.id,
                  onTap: () =>
                      setState(() => _selectedTemplateId = t.id),
                )),
          const SizedBox(height: 20),
          const Padding(
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
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.rMd),
                border: Border.all(color: AppTokens.outline),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate.toString(),
                      style: const TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.onSurface,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today,
                      size: 18, color: AppTokens.onSurfaceVar),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed:
                _selectedTemplateId == null ? null : _save,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('ایجاد برنامه'),
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

// ═══════════════ Queue notice ═══════════════

class _QueueNotice extends StatelessWidget {
  const _QueueNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        border: Border.all(
            color: AppTokens.primary.withValues(alpha: 0.30)),
      ),
      child: const Text(
        'این کلاینت برنامه فعال دارد. این برنامه جدید به صف اضافه می‌شود و بعد از تمام شدن برنامه فعلی فعال می‌شود.',
        style: TextStyle(
          fontFamily: 'Vazir',
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppTokens.primaryDark,
          height: 1.7,
        ),
      ),
    );
  }
}

// ═══════════════ No templates ═══════════════

class _NoTemplatesNotice extends StatelessWidget {
  const _NoTemplatesNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        border: Border.all(color: AppTokens.outlineVariant),
      ),
      child: const Text(
        'هنوز قالبی نساخته‌ای. اول از بخش برنامه‌ها یک قالب بساز.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Vazir',
          fontSize: 12.5,
          color: AppTokens.onSurfaceVar,
          height: 1.8,
        ),
      ),
    );
  }
}

// ═══════════════ Template option ═══════════════

class _TemplateOption extends StatelessWidget {
  final PlanTemplate template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateOption({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTokens.primary.withValues(alpha: 0.10)
              : AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.rMd),
          border: Border.all(
            color: selected
                ? AppTokens.primary
                : AppTokens.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTokens.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.fitness_center,
                  color: AppTokens.primary, size: 20),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _MiniTag(
                          text: '${fa(template.sessions)} جلسه'),
                      const SizedBox(width: 6),
                      _MiniTag(text: '${fa(template.days)} روز'),
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: AppTokens.primary, size: 22)
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTokens.outlineVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppTokens.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTokens.rSm),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Vazir',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTokens.onSurfaceVar,
        ),
      ),
    );
  }
}

// ═══════════════ Jalali date picker dialog ═══════════════

class _JalaliDatePickerDialog extends StatefulWidget {
  final jc.JalaliDate initial;
  const _JalaliDatePickerDialog({required this.initial});

  @override
  State<_JalaliDatePickerDialog> createState() =>
      _JalaliDatePickerDialogState();
}

class _JalaliDatePickerDialogState
    extends State<_JalaliDatePickerDialog> {
  late jc.JalaliDate _viewMonth;
  late jc.JalaliDate _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _viewMonth = jc.JalaliDate(
      widget.initial.year,
      widget.initial.month,
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalDays =
        jc.JalaliDate.monthDays(_viewMonth.year, _viewMonth.month);
    final firstWeekday = jc.JalaliDate.firstWeekdayOfMonth(
        _viewMonth.year, _viewMonth.month);
    final today = jc.JalaliDate.today();

    final cells = <Widget>[];
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int d = 1; d <= totalDays; d++) {
      final date = jc.JalaliDate(_viewMonth.year, _viewMonth.month, d);
      final isSelected = date == _selected;
      final isToday = date == today;

      Color bg = Colors.transparent;
      Color fg = AppTokens.onSurface;
      FontWeight weight = FontWeight.w600;
      if (isSelected) {
        bg = AppTokens.primary;
        fg = Colors.white;
        weight = FontWeight.w900;
      } else if (isToday) {
        bg = AppTokens.primary.withValues(alpha: 0.14);
        fg = AppTokens.primaryDark;
        weight = FontWeight.w900;
      }

      cells.add(GestureDetector(
        onTap: () => setState(() => _selected = date),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            fa(d),
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 12.5,
              fontWeight: weight,
              color: fg,
            ),
          ),
        ),
      ));
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.rXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'انتخاب تاریخ',
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
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
            SizedBox(
              width: 300,
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
                childAspectRatio: 1,
                children: cells,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('لغو',
                        style: TextStyle(fontFamily: 'Vazir')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.rMd),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Vazir',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('تایید'),
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