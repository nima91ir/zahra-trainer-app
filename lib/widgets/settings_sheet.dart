import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_tokens.dart';

/// Opens the settings bottom sheet.
Future<void> showSettingsSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTokens.rXl),
      ),
    ),
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    final name = context.read<AppState>().userName;
    _nameController.text = name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _confirmReset() async {
    final state = context.read<AppState>();
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'پاک کردن همه داده‌ها',
          style: TextStyle(
              fontFamily: 'Vazir', fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'همه کلاینت‌ها، برنامه‌ها، قالب‌ها و سوابق حضور پاک می‌شوند. این عملیات قابل بازگشت نیست.',
          style: TextStyle(fontFamily: 'Vazir', height: 1.8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('لغو',
                style: TextStyle(fontFamily: 'Vazir')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'پاک کن',
              style: TextStyle(
                fontFamily: 'Vazir',
                color: AppTokens.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.deleteAllData();
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'تنظیمات',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name input
              const Text(
                'نام شما (برای پیام خوش‌آمد)',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.onSurfaceVar,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'مثلاً زهرا',
                ),
                onChanged: (v) {
                  context.read<AppState>().setUserName(v);
                },
              ),
              const SizedBox(height: 20),

              // About
              _MenuItem(
                icon: Icons.info_outline,
                label: 'درباره',
                hint: 'Work Tracker · نسخه ۱.۰.۰',
                onTap: () => _showAbout(context),
              ),

              // Reset
              _MenuItem(
                icon: Icons.restart_alt,
                label: 'پاک کردن همه داده‌ها',
                hint: 'شروع دوباره با داده‌های نمونه',
                danger: true,
                onTap: _confirmReset,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Work Tracker',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Vazir', fontWeight: FontWeight.w800),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'این برنامه برای همسر عزیزم ساخته شده.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Vazir', fontSize: 13.5, height: 1.9),
            ),
            SizedBox(height: 8),
            Text(
              'امیدوارم بهت کمک کنه. 🌿',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Vazir', fontSize: 13.5, height: 1.9),
            ),
            SizedBox(height: 20),
            Text(
              'VERSION 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 11.5,
                letterSpacing: 1.2,
                color: AppTokens.onSurfaceVar,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('بستن',
                  style: TextStyle(fontFamily: 'Vazir')),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;
  final bool danger;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = danger ? AppTokens.errorSoft : AppTokens.primary.withValues(alpha: 0.14);
    final iconColor = danger ? AppTokens.error : AppTokens.primary;
    final labelColor = danger ? AppTokens.error : AppTokens.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTokens.surface,
            borderRadius: BorderRadius.circular(AppTokens.rMd),
            border: Border.all(color: AppTokens.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: const TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTokens.onSurfaceVar,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left,
                  size: 18, color: AppTokens.onSurfaceVar),
            ],
          ),
        ),
      ),
    );
  }
}