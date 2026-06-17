
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/alert_model.dart';
import '../utils/utils.dart';
import '../viewmodels/alerts_view_model.dart';
import 'alert_details_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);

    // Start polling when view model is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertsViewModel>().startPolling();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildSummaryBar(),
            _buildTabBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AlertsViewModel>(
      builder: (context, vm, _) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
          decoration: BoxDecoration(color: secondaryColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alerts &\nNotifications',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                      height: 1.1,
                      color: Colors.black87,
                    ),
                  ),
                  if (vm.lastUpdated != null) ...[
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Updated ${AlertFormatters.formatTime(vm.lastUpdated!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: grayColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              Icon(Icons.smart_toy_rounded, size: 54, color: primaryColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryBar() {
    return Consumer<AlertsViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading || vm.hasError) return const SizedBox.shrink();

        final critCount = vm.criticalAlerts.length;
        final warnCount = vm.warningAlerts.length;
        final isHealthy = vm.isHealthy;

        final bgColor = isHealthy
            ? const Color(0xFFF0FDF4)
            : (critCount > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1));

        final borderColor = isHealthy
            ? primaryColor.withAlpha(60)
            : (critCount > 0 ? redColor.withAlpha(60) : orangeColor.withAlpha(60));

        final icon = isHealthy
            ? Icons.verified_rounded
            : (critCount > 0 ? Icons.warning_amber_rounded : Icons.info_outline_rounded);

        final iconColor = isHealthy
            ? primaryColor
            : (critCount > 0 ? redColor : orangeColor);

        return Container(
          margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  isHealthy
                      ? 'All soil parameters are within optimal ranges.'
                      : '$critCount critical, $warnCount warning alert${(critCount + warnCount) != 1 ? 's' : ''} detected.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isHealthy ? primaryColor : Colors.black87,
                  ),
                ),
              ),
              if (!isHealthy)
                GestureDetector(
                  onTap: vm.refresh,
                  child: Icon(Icons.refresh_rounded, color: grayColor, size: 20),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Consumer<AlertsViewModel>(
      builder: (context, vm, _) {
        return Container(
          height: 45,
          margin: EdgeInsets.only(top: 12),
          color: primaryColor.withAlpha(50),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(color: Colors.white),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.black87,
            unselectedLabelColor: primaryColor,
            labelStyle: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                fontFamily: 'AbhayaLibre'),
            unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                fontFamily: 'AbhayaLibre'),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('All'),
                    if (vm.alerts.isNotEmpty) ...[
                      SizedBox(width: 6),
                      _buildTabBadge(vm.alerts.length, primaryColor),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Critical'),
                    if (vm.criticalAlerts.isNotEmpty) ...[
                      SizedBox(width: 6),
                      _buildTabBadge(vm.criticalAlerts.length, redColor),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Warning'),
                    if (vm.warningAlerts.isNotEmpty) ...[
                      SizedBox(width: 6),
                      _buildTabBadge(vm.warningAlerts.length, orangeColor),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBadge(int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<AlertsViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) return _buildLoadingState();
        if (vm.hasError) return _buildErrorState(vm);

        return TabBarView(
          controller: _tabController,
          children: [
            _buildAlertList(vm.alerts),
            _buildAlertList(vm.criticalAlerts),
            _buildAlertList(vm.warningAlerts),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
          SizedBox(height: 20),
          Text(
            'Analysing soil data...',
            style: TextStyle(
              color: grayColor,
              fontSize: 15,
              fontFamily: 'AbhayaLibre',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AlertsViewModel vm) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: redColor.withAlpha(60)),
              ),
              child: Column(
                children: [
                  Icon(Icons.sensors_off_rounded, color: redColor, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Could not connect to sensors',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    vm.errorMessage,
                    style: TextStyle(color: grayColor, fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            GestureDetector(
              onTap: vm.refresh,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withAlpha(80),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'AbhayaLibre',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertList(List<GeneratedAlert> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 60, color: primaryColor.withAlpha(120)),
            SizedBox(height: 16),
            Text(
              'No alerts in this category',
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
      padding: EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: items.length,
      separatorBuilder: (context, idx) => SizedBox(height: 14),
      itemBuilder: (ctx, i) => _AlertCard(alert: items[i]),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final GeneratedAlert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = AlertFormatters.severityColor(alert.severity);
    final bg = AlertFormatters.severityBg(alert.severity);
    final label = AlertFormatters.severityLabel(alert.severity);

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(50), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: severity badge + param + time
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(alert.icon, size: 14, color: color),
                      SizedBox(width: 5),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'AbhayaLibre',
                          letterSpacing: 0.8,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  AlertFormatters.formatTime(alert.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: grayColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),

            // Title
            Text(
              alert.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontFamily: 'AbhayaLibre',
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 6),

            // Description
            Text(
              alert.description,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: Colors.black87.withAlpha(180),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            if (alert.severity != AlertSeverity.info) ...[
              SizedBox(height: 14),

              // Value chip
              if (alert.value > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${alert.paramName}: ${alert.value.toStringAsFixed(alert.value < 10 ? 2 : 1)} ${alert.unit}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),

              SizedBox(height: 14),

              // CTA button
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: color,
                  borderRadius: BorderRadius.circular(25),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () => _navigateToDetails(context),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'View Recommendations',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'AbhayaLibre',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlertDetailsScreen(alert: alert),
      ),
    );
  }
}