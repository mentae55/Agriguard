// ============================================================
// spectral_history_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/spectral_history_view_model.dart';
import '../../data/models/spectral_history_entry.dart';
import 'spectral_history_details_screen.dart';

class SpectralHistoryScreen extends StatefulWidget {
  const SpectralHistoryScreen({super.key});

  @override
  State<SpectralHistoryScreen> createState() => _SpectralHistoryScreenState();
}

class _SpectralHistoryScreenState extends State<SpectralHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpectralHistoryViewModel>().loadHistory();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _riskColor(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':   return const Color(0xFFEF5350);
      case 'MEDIUM': return const Color(0xFFFFA726);
      default:       return const Color(0xFF66BB6A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Spectral History',
            style: TextStyle(fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w900)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF66785F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<SpectralHistoryViewModel>(
            builder: (_, vm, __) => PopupMenuButton<HistorySortOrder>(
              icon: const Icon(Icons.sort_rounded, color: Colors.white),
              onSelected: vm.setSortOrder,
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: HistorySortOrder.newestFirst,
                    child: Text('Newest First')),
                const PopupMenuItem(
                    value: HistorySortOrder.oldestFirst,
                    child: Text('Oldest First')),
                const PopupMenuItem(
                    value: HistorySortOrder.highestRisk,
                    child: Text('Highest Risk First')),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<SpectralHistoryViewModel>(
        builder: (context, vm, _) {
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: vm.setSearch,
                  decoration: InputDecoration(
                    hintText: 'Search by Plant ID, Disease, Group...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  children: HistoryFilter.values.map((f) {
                    final label = f == HistoryFilter.all ? 'All' : f.name.toUpperCase();
                    final selected = vm.filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => vm.setFilter(f),
                        selectedColor: const Color(0xFF66785F).withAlpha(180),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                            color: selected ? Colors.white : null,
                            fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // List
              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.entries.isEmpty
                        ? _EmptyHistoryView(
                            hasSearch: vm.searchQuery.isNotEmpty ||
                                vm.filter != HistoryFilter.all)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                            itemCount: vm.entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final entry = vm.entries[i];
                              return _HistoryCard(
                                entry: entry,
                                color: _riskColor(entry.riskLevel),
                                isDark: isDark,
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── History Card ─────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final SpectralHistoryEntry entry;
  final Color color;
  final bool isDark;

  const _HistoryCard(
      {required this.entry, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final formattedTime =
        '${entry.timestamp.day.toString().padLeft(2, '0')}/'
        '${entry.timestamp.month.toString().padLeft(2, '0')}/'
        '${entry.timestamp.year}  '
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SpectralHistoryDetailsScreen(entry: entry),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(80), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: color.withAlpha(isDark ? 30 : 15),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.plantId,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'AbhayaLibre')),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${entry.riskLevel} · ${entry.riskPercent}',
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${entry.predictedGroup} · ${entry.likelyDisease}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(160)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(formattedTime,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyHistoryView extends StatelessWidget {
  final bool hasSearch;
  const _EmptyHistoryView({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.history_rounded,
            size: 72,
            color: Colors.grey.withAlpha(120),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No matching results' : 'No spectral history yet',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'AbhayaLibre'),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try adjusting your search or filter'
                : 'Run a spectral analysis to see your history here',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
