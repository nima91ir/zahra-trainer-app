import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/jalali_calendar.dart' as jc;
import '../../utils/persian_numbers.dart';
import '../../widgets/client_card.dart';
import '../../widgets/settings_sheet.dart';
import '../add_edit_client/add_edit_client_screen.dart';
import '../client_detail/client_detail_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _searchQuery = '';
  final Set<int> _selectedTagIds = {};

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final todayStr = jc.JalaliDate.today().toString();

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final validClients = state.clients.where((c) => c.id != null).toList();
    List filteredClients = validClients.where((c) {
      final matchesSearch = _searchQuery.isEmpty ||
          c.name.contains(_searchQuery) ||
          (c.contact?.contains(_searchQuery) ?? false);
      bool matchesTag = true;
      if (_selectedTagIds.isNotEmpty) {
        matchesTag = _selectedTagIds.every((tagId) => c.tagIds.contains(tagId));
      }
      return matchesSearch && matchesTag;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('کلاینت‌ها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: state.clients.isEmpty
          ? const _EmptyStateContent()
          : Column(
              children: [
                Container(
                  color: AppTokens.background,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    children: [
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTokens.surface,
                          borderRadius: BorderRadius.circular(AppTokens.rMd),
                          border: Border.all(color: AppTokens.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppTokens.onSurfaceVar, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'جستجوی کلاینت...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(fontFamily: 'Vazir', color: AppTokens.onSurfaceVar, fontSize: 14),
                                ),
                                style: const TextStyle(fontFamily: 'Vazir', color: AppTokens.onSurface, fontSize: 14),
                                onChanged: (val) => setState(() => _searchQuery = val),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                             _FilterChip(label: 'همه', count: validClients.length, isActive: _selectedTagIds.isEmpty, onTap: () => setState(() => _selectedTagIds.clear())),
                             const SizedBox(width: 8),
                             ...state.tags.map((tag) {
                               final count = validClients.where((c) => c.tagIds.contains(tag.id)).length;
                               if (count == 0 && !_selectedTagIds.contains(tag.id)) return const SizedBox.shrink();
                               final isActive = _selectedTagIds.contains(tag.id);
                               return Padding(
                                 padding: const EdgeInsets.only(left: 8),
                                 child: _FilterChip(label: tag.name, count: count, isActive: isActive, onTap: () {
                                   setState(() {
                                     if (isActive) {
                                       _selectedTagIds.remove(tag.id);
                                     } else {
                                       _selectedTagIds.add(tag.id!);
                                     }
                                   });
                                 }),
                               );
                             }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredClients.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: AppTokens.onSurfaceVar),
                                SizedBox(height: 12),
                                Text('نتیجه‌ای پیدا نشد', style: TextStyle(fontFamily: 'Vazir', fontSize: 13, color: AppTokens.onSurfaceVar)),
                                if (_selectedTagIds.isNotEmpty || _searchQuery.isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () => setState(() {
                                      _selectedTagIds.clear();
                                      _searchQuery = '';
                                    }),
                                    icon: Icon(Icons.filter_list_off_rounded, size: 18),
                                    label: Text('پاک کردن فیلترها', style: TextStyle(fontFamily: 'Vazir')),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          itemCount: filteredClients.length,
                          itemBuilder: (context, index) {
                            final c = filteredClients[index];
                            if (c.id == null) return const SizedBox.shrink();
                            final plan = state.activePlanForClient(c.id!);
                            final todayRec = state.attendance.where((a) => a.clientId == c.id && a.date == todayStr).toList();
                            final hasAttended = todayRec.isNotEmpty;
                            final status = hasAttended ? todayRec.first.status : null;
                            return ClientCard(
                              client: c,
                              activePlan: plan,
                              hasAttendedToday: hasAttended,
                              todayStatus: status,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDetailScreen(clientId: c.id!))),
                              onMarkPresent: () => state.markAttendance(c.id!, 'present', todayStr),
                              onMarkAbsent: () => state.markAttendance(c.id!, 'absent', todayStr),
                              onUndoAttendance: () => state.undoAttendance(c.id!, todayStr),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTokens.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditClientScreen())),
        heroTag: 'clients_fab',
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.count, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTokens.primary : AppTokens.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isActive ? AppTokens.primary : AppTokens.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Vazir', fontSize: 12.5, fontWeight: FontWeight.w700, color: isActive ? Colors.white : AppTokens.onSurfaceVar)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: isActive ? Colors.white.withValues(alpha: 0.28) : AppTokens.surfaceVariant, borderRadius: BorderRadius.circular(999)),
              child: Text(fa(count), style: TextStyle(fontFamily: 'Vazir', fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? Colors.white : AppTokens.onSurfaceVar)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateContent extends StatelessWidget {
  const _EmptyStateContent();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppTokens.onSurfaceVar),
          SizedBox(height: 16),
          Text('هنوز کلاینتی نداری', style: TextStyle(fontFamily: 'Vazir', fontSize: 16, fontWeight: FontWeight.w800, color: AppTokens.onSurface)),
          SizedBox(height: 4),
          Text('اولین کلاینتت را اضافه کن', style: TextStyle(fontFamily: 'Vazir', fontSize: 13, color: AppTokens.onSurfaceVar)),
        ],
      ),
    );
  }
}