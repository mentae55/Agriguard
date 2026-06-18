import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/alert_model.dart';
import '../utils/utils.dart';
import '../viewmodels/alerts_view_model.dart';
import 'alert_details_screen.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<AlertsViewModel>(
      builder: (context, vm, _) {
        final history = List<GeneratedAlert>.from(vm.history);
        
        // Sort newest first
        history.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Compute stats
        final totalCount = history.length;
        final activeCount = history.where((a) => !a.isResolved).length;
        final resolvedCount = history.where((a) => a.isResolved).length;
        final criticalCount = history.where((a) => a.severity == AlertSeverity.critical).length;

        // Filter list
        final filteredList = history.where((alert) {
          switch (_selectedFilter) {
            case 'Active':
              return !alert.isResolved;
            case 'Resolved':
              return alert.isResolved;
            case 'Critical':
              return alert.severity == AlertSeverity.critical;
            case 'Warning':
              return alert.severity == AlertSeverity.warning;
            default:
              return true;
          }
        }).toList();

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: colorScheme.secondary,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Alert History',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFamily: 'AbhayaLibre',
                color: colorScheme.onSurface,
              ),
            ),
            actions: [
              if (history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 26),
                  tooltip: 'Clear History',
                  onPressed: () => _showClearDialog(context, vm),
                ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatsDashboard(
                theme: theme,
                isDark: isDark,
                total: totalCount,
                active: activeCount,
                resolved: resolvedCount,
                critical: criticalCount,
              ),
              _buildFilterBar(theme),
              Expanded(
                child: _buildHistoryList(filteredList, theme, isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsDashboard({
    required ThemeData theme,
    required bool isDark,
    required int total,
    required int active,
    required int resolved,
    required int critical,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: theme.colorScheme.secondary.withAlpha(50),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.9,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStatCard(
            title: 'Total',
            value: '$total',
            color: theme.primaryColor,
            bg: isDark ? const Color(0xFF1E3A24) : const Color(0xFFE8F5E9),
          ),
          _buildStatCard(
            title: 'Active',
            value: '$active',
            color: Colors.orange.shade800,
            bg: isDark ? const Color(0xFF3E2723) : const Color(0xFFFFE0B2),
          ),
          _buildStatCard(
            title: 'Resolved',
            value: '$resolved',
            color: Colors.green.shade800,
            bg: isDark ? const Color(0xFF1B5E20).withAlpha(100) : const Color(0xFFC8E6C9),
          ),
          _buildStatCard(
            title: 'Critical',
            value: '$critical',
            color: Colors.red.shade800,
            bg: isDark ? const Color(0xFF4A141C) : const Color(0xFFFFCDD2),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color.withAlpha(200),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    final filters = ['All', 'Active', 'Resolved', 'Critical', 'Warning'];
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final filter = filters[idx];
          final isSelected = _selectedFilter == filter;

          return ChoiceChip(
            label: Text(
              filter,
              style: TextStyle(
                fontFamily: 'AbhayaLibre',
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? theme.colorScheme.onPrimary : theme.primaryColor,
              ),
            ),
            selected: isSelected,
            selectedColor: theme.primaryColor,
            backgroundColor: theme.colorScheme.surface,
            onSelected: (val) {
              if (val) {
                setState(() => _selectedFilter = filter);
              }
            },
            elevation: isSelected ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? Colors.transparent : theme.primaryColor.withAlpha(80),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(List<GeneratedAlert> items, ThemeData theme, bool isDark) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 60, color: theme.primaryColor.withAlpha(100)),
            const SizedBox(height: 16),
            Text(
              'No alert history found',
              style: TextStyle(
                color: grayColor,
                fontFamily: 'AbhayaLibre',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final alert = items[idx];
        return _AlertHistoryCard(alert: alert);
      },
    );
  }

  void _showClearDialog(BuildContext context, AlertsViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Clear Alert History?',
          style: TextStyle(fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w900),
        ),
        content: const Text('This action will permanently erase all local alert history. Unresolved/active alerts will be reset to healthy status.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: grayColor)),
          ),
          TextButton(
            onPressed: () {
              vm.clearAlertHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AlertHistoryCard extends StatelessWidget {
  final GeneratedAlert alert;

  const _AlertHistoryCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final color = AlertFormatters.severityColor(alert.severity);
    final bg = AlertFormatters.severityBg(alert.severity, isDark: isDark);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlertDetailsScreen(alert: alert),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: alert.isResolved 
                ? theme.dividerColor.withAlpha(70) 
                : color.withAlpha(80), 
            width: alert.isResolved ? 1.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withAlpha(20) : Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(alert.icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        AlertFormatters.severityLabel(alert.severity),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(theme),
                const Spacer(),
                Text(
                  AlertFormatters.formatTime(alert.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: grayColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                fontFamily: 'AbhayaLibre',
                color: alert.isResolved ? colorScheme.onSurface.withAlpha(160) : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              alert.description,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withAlpha(140),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (alert.value > 0)
                  Text(
                    '${alert.paramName}: ${alert.value.toStringAsFixed(1)} ${alert.unit}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: alert.isResolved ? colorScheme.onSurface.withAlpha(120) : color,
                    ),
                  ),
                if (alert.isResolved && alert.resolvedAt != null)
                  Text(
                    'Resolved at ${AlertFormatters.formatTime(alert.resolvedAt!)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final isResolved = alert.isResolved;
    final text = isResolved ? 'Resolved' : 'Active';
    final color = isResolved ? Colors.green : Colors.orange.shade800;
    final bg = isResolved ? const Color(0xFFE8F5E9) : const Color(0xFFFFE0B2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
