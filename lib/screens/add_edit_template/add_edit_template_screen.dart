import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/plan_template.dart';
import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/persian_numbers.dart';
import '../../widgets/settings_sheet.dart';

String _persianToEnglishDigits(String input) {
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  String result = input;
  for (int i = 0; i < persian.length; i++) {
    result = result.replaceAll(persian[i], english[i]);
  }
  return result;
}

class AddEditTemplateScreen extends StatefulWidget {
  final PlanTemplate? existing;
  const AddEditTemplateScreen({super.key, this.existing});

  @override
  State<AddEditTemplateScreen> createState() => _AddEditTemplateScreenState();
}

class _AddEditTemplateScreenState extends State<AddEditTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _sessionsController;
  late TextEditingController _daysController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _sessionsController = TextEditingController(
        text: widget.existing?.sessions != null ? fa(widget.existing!.sessions) : '');
    _daysController = TextEditingController(
        text: widget.existing?.days != null ? fa(widget.existing!.days) : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sessionsController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {}); // Rebuild to update preview and button state
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    final nav = Navigator.of(context);
    final isEdit = widget.existing != null;

    final sessions = int.parse(_persianToEnglishDigits(_sessionsController.text));
    final days = int.parse(_persianToEnglishDigits(_daysController.text));

    final template = PlanTemplate(
      id: widget.existing?.id,
      name: _nameController.text.trim(),
      sessions: sessions,
      days: days,
    );

    if (isEdit) {
      await state.updateTemplate(template);
    } else {
      await state.addTemplate(template);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'قالب ویرایش شد' : 'قالب ساخته شد',
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
    final isEdit = widget.existing != null;

    // Parse inputs for preview
    final name = _nameController.text.trim();
    final sessionsText = _persianToEnglishDigits(_sessionsController.text);
    final daysText = _persianToEnglishDigits(_daysController.text);
    
    final sessions = int.tryParse(sessionsText) ?? 0;
    final days = int.tryParse(daysText) ?? 0;
    final isValid = name.isNotEmpty && sessions > 0 && days > 0;

    // Calculate weeks
    final weeks = days ~/ 7;
    final remDays = days % 7;
    String weeksText = '';
    if (weeks > 0) weeksText += '${fa(weeks)} هفته';
    if (remDays > 0) {
      if (weeks > 0) weeksText += ' و ';
      weeksText += '${fa(remDays)} روز';
    }

    // Check usage for warning
    int usageCount = 0;
    if (isEdit && widget.existing!.id != null) {
      usageCount = state.plans.where((p) => 
        p.templateId == widget.existing!.id && 
        (p.status == 'active' || p.status == 'frozen')
      ).length;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'ویرایش قالب' : 'افزودن قالب'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, size: 22),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _nameController,
              onChanged: (_) => _onChanged(),
              decoration: InputDecoration(
                labelText: 'نام قالب *',
                hintText: 'مثلاً برنامه لاغری',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'نام را وارد کنید' : null,
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _sessionsController,
              onChanged: (_) => _onChanged(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'تعداد جلسات *',
                hintText: '۱۲',
              ),
              validator: (v) {
                final val = int.tryParse(_persianToEnglishDigits(v ?? ''));
                return (val == null || val <= 0) ? 'تعداد معتبر وارد کنید' : null;
              },
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _daysController,
              onChanged: (_) => _onChanged(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'مدت اعتبار (روز) *',
                hintText: '۲۸',
              ),
              validator: (v) {
                final val = int.tryParse(_persianToEnglishDigits(v ?? ''));
                return (val == null || val <= 0) ? 'مدت معتبر وارد کنید' : null;
              },
            ),
            SizedBox(height: 20),

            // Preview Box
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
                  Text(
                    'پیش‌نمایش',
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.primary,
                      letterSpacing: 0.08,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    name.isEmpty ? '—' : name,
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.onSurface,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    isValid ? '${fa(sessions)} جلسه در ${fa(days)} روز' : 'اطلاعات را وارد کنید',
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 13,
                      color: isValid ? AppTokens.onSurfaceVar : AppTokens.onSurfaceVar.withValues(alpha: 0.6),
                      height: 1.7,
                    ),
                  ),
                  if (isValid && weeksText.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTokens.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTokens.rSm),
                      ),
                      child: Text(
                        'معادل $weeksText',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTokens.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Warning Box
            if (isEdit && usageCount > 0) ...[
              SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTokens.warningSoft,
                  borderRadius: BorderRadius.circular(AppTokens.rMd),
                ),
                child: Text(
                  '⚠️ در ${fa(usageCount)} برنامه فعال استفاده شده. تغییرات روی آن‌ها اعمال می‌شود.',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.warning,
                    height: 1.7,
                  ),
                ),
              ),
            ],

            SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: isValid ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTokens.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTokens.outlineVariant,
                  disabledForegroundColor: AppTokens.onSurfaceVar,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.rLg),
                  ),
                  textStyle: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(isEdit ? 'ذخیره تغییرات' : 'ذخیره قالب'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
