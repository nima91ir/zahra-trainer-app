import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/tag.dart';
import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/persian_numbers.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  static const List<String> _emojis = [
    '🏋️', '💻', '🌅', '🚴', '🧘', '⚽',
    '🏊', '🤸', '💪', '🩺', '🌙', '☀️',
    '🎯', '🏆', '⭐', '❤️', '🔥', '🌸',
    '🍎', '🥗', '📅', '🕐', '🏠', '📱',
  ];

  String _newEmoji = '🏋️';
  final TextEditingController _nameController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('نام را وارد کنید', style: TextStyle(fontFamily: 'Vazir')),
        ),
      );
      return;
    }
    final state = context.read<AppState>();
    if (state.tags.any((t) => t.name == name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('این برچسب وجود دارد',
              style: TextStyle(fontFamily: 'Vazir')),
        ),
      );
      return;
    }
    await state.addTag(Tag(emoji: _newEmoji, name: name));
    _nameController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('برچسب اضافه شد', style: TextStyle(fontFamily: 'Vazir')),
        ),
      );
    }
  }

  Future<void> _confirmDelete(Tag tag, int usage) async {
    final state = context.read<AppState>();
    final warning = usage > 0
        ? '\n\nاین برچسب در ${fa(usage)} کلاینت استفاده شده. از روی آن‌ها هم برداشته می‌شود.'
        : '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف برچسب',
          style:
              TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.w800),
        ),
        content: Text(
          'آیا از حذف «${tag.emoji} ${tag.name}» اطمینان داری؟$warning',
          style: TextStyle(fontFamily: 'Vazir', height: 1.8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('لغو',
                style: TextStyle(fontFamily: 'Vazir')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'حذف',
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
    if (ok == true && tag.id != null) {
      await state.deleteTag(tag.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text('برچسب‌ها')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'برچسب‌هایی که برای گروه‌بندی کلاینت‌ها می‌خواهی بساز.',
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 12.5,
                color: AppTokens.onSurfaceVar,
                height: 1.8,
              ),
            ),
          ),
          SizedBox(height: 16),

          if (state.tags.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.rMd),
                border: Border.all(color: AppTokens.outlineVariant),
              ),
              child: Text(
                'هنوز برچسبی نساخته‌ای.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 12.5,
                  color: AppTokens.onSurfaceVar,
                ),
              ),
            )
          else
            ...state.tags.map((tag) {
              final usage = state.clients
                  .where((c) => c.tagIds.contains(tag.id))
                  .length;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
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
                        color: AppTokens.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tag.emoji,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tag.name,
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTokens.onSurface,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            usage > 0
                                ? 'در ${fa(usage)} کلاینت'
                                : 'استفاده نشده',
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 11,
                              color: AppTokens.onSurfaceVar,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18),
                      color: AppTokens.error,
                      onPressed: () => _confirmDelete(tag, usage),
                    ),
                  ],
                ),
              );
            }),

          SizedBox(height: 20),

          // Add new tag form
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.rMd),
              border: Border.all(
                color: AppTokens.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Emoji preview / dropdown
                    PopupMenuButton<String>(
                      onSelected: (e) =>
                          setState(() => _newEmoji = e),
                      itemBuilder: (ctx) => _emojis
                          .map((e) => PopupMenuItem(
                                value: e,
                                child: Text(e,
                                    style:
                                        TextStyle(fontSize: 22)),
                              ))
                          .toList(),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTokens.surface,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppTokens.outline),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _newEmoji,
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'نام برچسب (مثلاً باشگاه)',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _add,
                  icon: Icon(Icons.add, size: 18),
                  label: Text('افزودن برچسب'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTokens.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.rMd),
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
        ],
      ),
    );
  }
}
