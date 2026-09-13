import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/plan_template.dart';
import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/persian_numbers.dart';

class AddEditTemplateScreen extends StatefulWidget {
  final PlanTemplate? existing;
  const AddEditTemplateScreen({super.key, this.existing});

  @override
  State<AddEditTemplateScreen> createState() =>
      _AddEditTemplateScreenState();
}

class _AddEditTemplateScreenState
    extends State<AddEditTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _sessionsController;
  late TextEditingController _daysController;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _nameController = TextEditingController(text: t?.name ?? '');
    _sessionsController = TextEditingController(
        text: t != null && t.sessions > 0 ? t.sessions.toString() : '');
    _daysController = TextEditingController(
        text: t != null && t.days > 0 ? t.days.toString() : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sessionsController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    final nav = Navigator.of(context);
    final isEdit = widget.existing != null;

    final sessions = int.parse(_sessionsController.text.trim());
    final days = int.parse(_daysController.text.trim());

    final template = PlanTemplate(
      id: widget.existing?.id,
      name: _nameController.text.trim(),
      sessions: sessions,
      days: days,
    );

    // Find how many plans use this template (for warning on edit)
    final usageCount = isEdit
        ? state.plans
            .where((p) => p.templateId == widget.existing!.id)
            .length
        : 0;

    if (isEdit && usageCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'ذخیره تغییرات؟',
            style: TextStyle(
                fontFamily: 'Vazir', fontWeight: FontWeight.w800),
          ),
          content: Text(
            'این قالب در ${fa(usageCount)} برنامه استفاده شده. تغییرات روی برنامه‌های فعال اعمال می‌شود.',
            style: const TextStyle(fontFamily: 'Vazir', height: 1.8),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لغو',
                  style: TextStyle(fontFamily: 'Vazir')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ذخیره',
                  style: TextStyle(
                      fontFamily: 'Vazir',
                      color: AppTokens.primary,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

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
            style: const TextStyle(fontFamily: 'Vazir'),
          ),
        ),
      );
      nav.pop();
    }
  }

  String _previewText() {
    final sessions = int.tryParse(_sessionsController.text.trim());
    final days = int.tryParse(_daysController.text.trim());
    if (sessions == null || days == null || sessions <= 0 || days <= 0) {
      return '';
    }
    final weeks = days ~/ 7;
    final rem = days % 7;
    String weeksText = 'معادل ';
    if (weeks > 0) weeksText += '${fa(weeks)} هفته';
    if (rem > 0) {
      if (weeks > 0) weeksText += ' و ';
      weeksText += '${fa(rem)} روز';
    }
    return weeksText;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final state = context.watch<AppState>();
    final name = _nameController.text.trim();
    final sessions = int.tryParse(_sessionsController.text.trim());
    final days = int.tryParse(_daysController.text.trim());
    final hasPreview =
        name.isNotEmpty && sessions != null && days != null &&
        sessions > 0 && days > 0;

    // Warning for edit mode
    final usageCount = isEdit
        ? state.plans
            .where((p) => p.templateId == widget.existing!.id)
            .length
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'ویرایش قالب' : 'افزودن قالب'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'نام قالب *',
                hintText: 'مثلاً برنامه لاغری',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'نام را وارد کنید';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _sessionsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'تعداد جلسات *',
                hintText: '۱۲',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) {
                  return 'عدد معتبر وارد کنید';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مدت اعتبار (روز) *',
                hintText: '۲۸',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) {
                  return 'عدد معتبر وارد کنید';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            if (hasPreview)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTokens.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTokens.rMd),
                  border: Border.all(
                      color: AppTokens.primary.withValues(alpha: 0.35),
                      width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'پیش‌نمایش',
                      style: TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fa(sessions)} جلسه در ${fa(days)} روز',
                      style: const TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.onSurfaceVar,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTokens.surface,
                        borderRadius: BorderRadius.circular(AppTokens.rSm),
                      ),
                      child: Text(
                        _previewText(),
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (isEdit && usageCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTokens.warningSoft,
                  borderRadius: BorderRadius.circular(AppTokens.rMd),
                ),
                child: Text(
                  '⚠️ این قالب در ${fa(usageCount)} برنامه استفاده شده. تغییرات روی برنامه‌های فعال اعمال می‌شود.',
                  style: const TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.warning,
                    height: 1.7,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, size: 18),
              label: Text(isEdit ? 'ذخیره تغییرات' : 'ذخیره قالب'),
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
      ),
    );
  }
}