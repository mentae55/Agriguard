import 'package:flutter/material.dart';
import 'package:agriguard_project/core/core.dart';
import 'alert_details_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: secondaryColor, // Soft beige/cream
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alerts &\nNotifications',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                      height: 1.1,
                      color: Colors.black87,
                    ),
                  ),
                  Icon(
                    Icons.smart_toy_rounded,
                    size: 54,
                    color: primaryColor,
                  ),
                ],
              ),
            ),

            // Custom TabBar
            Container(
              height: 45,
              color: primaryColor.withAlpha(50),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.black87,
                unselectedLabelColor: primaryColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, fontFamily: 'AbhayaLibre'),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'AbhayaLibre'),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Critical'),
                  Tab(text: 'Warning'),
                ],
              ),
            ),

            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllAlerts(context),
                  _buildAllAlerts(context), // Placeholder for Critical filter
                  _buildAllAlerts(context), // Placeholder for Warning filter
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllAlerts(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        _buildCriticalAlertCard(context),
        const SizedBox(height: 16),
        _buildWarningAlertCard(context),
        const SizedBox(height: 80), // For bottom nav
      ],
    );
  }

  Widget _buildCriticalAlertCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7).withAlpha(150), // Pale green
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 36),
              const SizedBox(width: 12),
              Text(
                'CRITICAL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                  letterSpacing: 1.2,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Critical Nitrogen Deficiency Detected',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Low Nitrogen levels in North Sector, Rows 40-50. Immediate fertilization recommended to prevent yield loss.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: Colors.black87.withAlpha(200),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '13 Feb 10:15 AM',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context: context,
                  label: 'View Recommendations',
                  color: Colors.red.shade700,
                  isPrimary: true,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWarningAlertCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7).withAlpha(150), // Pale green
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade500,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'WARNING',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                  letterSpacing: 1.2,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Robot Battery LOW',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Battery is at 15%. Returning to base for charging',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: Colors.black87.withAlpha(200),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '14 Feb 5:30 AM',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              context: context,
              label: 'Track Robot',
              color: Colors.orange.shade500,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required Color color,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: () {
        if (label == 'View Recommendations') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertDetailsScreen()));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: isPrimary ? null : Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'AbhayaLibre',
            ),
          ),
        ),
      ),
    );
  }
}
