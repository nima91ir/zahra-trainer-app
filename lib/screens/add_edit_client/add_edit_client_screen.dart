import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/client.dart';
import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/jalali_calendar.dart' as jc;
import '../../utils/persian_numbers.dart';
import '../../widgets/jalali_calendar.dart';

class AddEditClientScreen extends StatefulWidget {
  final Client? existing;
  const AddEditClientScreen({super.key, this.existing});

  @override
  State<AddEditClientScreen> createState() => _AddEditClientScreenState();
}

class _AddEditClientScreenState extends State<AddEditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _noteController;
  final List<int> _selectedTagIds = [];

  // Plan section state
  bool _showPlanSection = false;
  int? _selectedTemplateId;
  String _selectedStartDate = '';

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameController = TextEditingController(text: c?.name ?? '');
    _contactController = TextEditingController(text: c?.contact ?? '');
    _noteController = TextEditingController(text: c?.note ?? '');
    if (c != null) {
      _selectedTagIds.addAll(c.tagIds);
    } else {
      // Default start date for new clients
      _selectedStartDate = jc.JalaliDate.today().toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    final nav = Navigator.of(context);
    final isEdit = widget.existing != null;

    final client = Client(
      id: widget.existing?.id,
      name: _nameController.text.trim(),
      contact: _contactController.text.trim().isEmpty
          ? null
          : _contactController.text.trim(),
      tagIds: List.of(_selectedTagIds),
      note: _noteController.text.trim(),
      bonusSessions: widget.existing?.bonusSessions ?? 0,
    );

    if (isEdit) {
      await state.updateClient(client);
    } else {
      final newClientId = await state.addClient(client);
      
      // If adding a plan for the new client
      if (_showPlanSection && _selectedTemplateId != null && newClientId != null) {
         await state.addPlan(
           clientId: newClientId,
           templateId: _selectedTemplateId!,
           startDate: _selectedStartDate,
         );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'کلاینت ویرایش شد' : 'کلاینت اضافه شد',
            style: TextStyle(fontFamily: 'Vazir'),
          ),
        ),
      );
      nav.pop();
    }
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
      setState(() => _selectedStartDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'ویرایش کلاینت' : 'افزودن کلاینت'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'نام کامل *',
                hintText: 'مثلاً سارا احمدی',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'نام را وارد کنید';
                }
                return null;
              },
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'شماره تماس (اختیاری)',
                hintText: '۰۹۱۲ ۰۰۰ ۰۰۰۰',
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'برچسب‌ها',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.onSurfaceVar,
                ),
              ),
            ),
            SizedBox(height: 8),
            if (state.tags.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'هنوز برچسبی نساخته‌ای.',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 12,
                    color: AppTokens.onSurfaceVar,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.tags.map((t) {
                  final checked = _selectedTagIds.contains(t.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (checked) {
                          _selectedTagIds.remove(t.id);
                        } else {
                          _selectedTagIds.add(t.id!);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: checked
                            ? AppTokens.primary.withValues(alpha: 0.14)
                            : AppTokens.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: checked
                              ? AppTokens.primary
                              : AppTokens.outlineVariant,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        t.name, // Remove emoji from tag selection chips
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: checked
                              ? AppTokens.primary
                              : AppTokens.onSurfaceVar,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: 20),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'یادداشت (اختیاری)',
                hintText: 'مثلاً پارگی مینیسک',
              ),
            ),
            
            // Add Plan Section (Only for new clients)
            if (!isEdit) ...[
              SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTokens.surface,
                  borderRadius: BorderRadius.circular(AppTokens.rMd),
                  border: Border.all(color: AppTokens.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'افزودن برنامه (اختیاری)',
                          style: TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.onSurface,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _showPlanSection = !_showPlanSection),
                          child: Text(
                            _showPlanSection ? 'حذف' : 'افزودن',
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTokens.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showPlanSection) ...[
                      SizedBox(height: 12),
                      if (state.templates.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'برای افزودن برنامه، اول باید یک قالب بسازی.',
                            style: TextStyle(fontFamily: 'Vazir', fontSize: 12.5, color: AppTokens.onSurfaceVar),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else ...[
                        Text(
                          'انتخاب قالب',
                          style: TextStyle(fontFamily: 'Vazir', fontSize: 12, fontWeight: FontWeight.w700, color: AppTokens.onSurfaceVar),
                        ),
                        SizedBox(height: 8),
                        ...state.templates.map((t) {
                          final isSelected = _selectedTemplateId == t.id;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedTemplateId = t.id),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
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
                                    decoration: BoxDecoration(color: AppTokens.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.fitness_center, color: AppTokens.primary, size: 20),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.name, style: TextStyle(fontFamily: 'Vazir', fontSize: 14, fontWeight: FontWeight.w800, color: AppTokens.onSurface)),
                                        SizedBox(height: 4),
                                        Row(children: [
                                          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: AppTokens.surfaceVariant, borderRadius: BorderRadius.circular(AppTokens.rSm)), child: Text('${fa(t.sessions)} جلسه', style: TextStyle(fontFamily: 'Vazir', fontSize: 11, fontWeight: FontWeight.w700, color: AppTokens.onSurfaceVar))),
                                          SizedBox(width: 6),
                                          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: AppTokens.surfaceVariant, borderRadius: BorderRadius.circular(AppTokens.rSm)), child: Text('${fa(t.days)} روز', style: TextStyle(fontFamily: 'Vazir', fontSize: 11, fontWeight: FontWeight.w700, color: AppTokens.onSurfaceVar))),
                                        ]),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        SizedBox(height: 12),
                        Text(
                          'تاریخ شروع',
                          style: TextStyle(fontFamily: 'Vazir', fontSize: 12, fontWeight: FontWeight.w700, color: AppTokens.onSurfaceVar),
                        ),
                        SizedBox(height: 8),
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
                                Text(_selectedStartDate.isEmpty ? 'انتخاب تاریخ' : _selectedStartDate, style: TextStyle(fontFamily: 'Vazir', fontSize: 15, fontWeight: FontWeight.w600, color: AppTokens.onSurface)),
                                Icon(Icons.calendar_today, size: 18, color: AppTokens.onSurfaceVar),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],

            SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(Icons.check, size: 18),
              label: Text(isEdit ? 'ذخیره تغییرات' : 'ذخیره کلاینت'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.rLg),
                ),
                textStyle: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
