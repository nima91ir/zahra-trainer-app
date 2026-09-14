import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/plan_template.dart';
import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/persian_numbers.dart';
import '../add_edit_template/add_edit_template_screen.dart';

import '../../widgets/settings_sheet.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('برنامه‌ها'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, size: 22),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: state.templates.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'اینجا قالب‌های برنامه‌ات را می‌سازی. موقع افزودن برنامه به کلاینت، یکی از این‌ها را انتخاب می‌کنی.',
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.onSurfaceVar,
                      height: 1.8,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ...state.templates.map((t) => _TemplateCard(
                      template: t,
                      usageCount: state.plans
                          .where((p) => p.templateId == t.id)
                          .length,
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTokens.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditTemplateScreen(),
            ),
          );
        },
        heroTag: 'templates_fab',
        child: Icon(Icons.add, size: 26),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final PlanTemplate template;
  final int usageCount;
  const _TemplateCard({required this.template, required this.usageCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        border: Border.all(color: AppTokens.outlineVariant),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTokens.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.fitness_center,
                color: AppTokens.primary, size: 20),
          ),
          SizedBox(width: 12),

          // Body
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
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
                    _MiniTag(text: '${fa(template.sessions)} جلسه'),
                    SizedBox(width: 6),
                    _MiniTag(text: '${fa(template.days)} روز'),
                  ],
                ),
                if (usageCount > 0) ...[
                  SizedBox(height: 6),
                  Text(
                    'در ${fa(usageCount)} برنامه استفاده شده',
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.warning,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Edit button
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18),
            color: AppTokens.onSurfaceVar,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddEditTemplateScreen(existing: template),
                ),
              );
            },
          ),

          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18),
            color: AppTokens.error,
            onPressed: () {
              _showDeleteDialog(context, template, usageCount);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, PlanTemplate template, int usageCount) {
    final state = context.read<AppState>();
    final warning = usageCount > 0
        ? '\n\nهشدار: این قالب در ${fa(usageCount)} برنامه استفاده شده. حذف قالب، برنامه‌های موجود را حذف نمی‌کند.'
        : '';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف قالب',
            style: TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.w800)),
        content: Text(
          'آیا از حذف «${template.name}» اطمینان داری؟$warning',
          style: TextStyle(fontFamily: 'Vazir', height: 1.8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('لغو',
                style: TextStyle(fontFamily: 'Vazir')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (template.id != null) {
                state.deleteTemplate(template.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('قالب حذف شد')),
                );
              }
            },
            child: Text('حذف',
                style: TextStyle(
                    fontFamily: 'Vazir',
                    color: AppTokens.error,
                    fontWeight: FontWeight.w700)),
          ),
        ],
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
        style: TextStyle(
          fontFamily: 'Vazir',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTokens.onSurfaceVar,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'هنوز برنامه‌ای نساخته‌ای',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
