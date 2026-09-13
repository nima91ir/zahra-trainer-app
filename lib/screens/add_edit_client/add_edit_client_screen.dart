import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/client.dart';
import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';

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

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameController = TextEditingController(text: c?.name ?? '');
    _contactController = TextEditingController(text: c?.contact ?? '');
    _noteController = TextEditingController(text: c?.note ?? '');
    if (c != null) _selectedTagIds.addAll(c.tagIds);
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
      await state.addClient(client);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'کلاینت ویرایش شد' : 'کلاینت اضافه شد',
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
              decoration: const InputDecoration(
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
            const SizedBox(height: 14),
            TextFormField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'شماره تماس (اختیاری)',
                hintText: '۰۹۱۲ ۰۰۰ ۰۰۰۰',
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
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
            const SizedBox(height: 8),
            if (state.tags.isEmpty)
              const Padding(
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
                        '${t.emoji} ${t.name}',
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
            const SizedBox(height: 20),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'یادداشت (اختیاری)',
                hintText: 'مثلاً پارگی مینیسک',
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, size: 18),
              label: Text(isEdit ? 'ذخیره تغییرات' : 'ذخیره کلاینت'),
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