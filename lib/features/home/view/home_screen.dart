import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:agriguard_project/core/core.dart';
import 'package:agriguard_project/features/connection_to_device/view/select_device_screen.dart';
import 'package:agriguard_project/features/alerts/view/alerts_screen.dart';
import 'package:agriguard_project/features/alerts/models/alert_model.dart';
import 'package:agriguard_project/features/alerts/models/soil_alert_engine.dart';
import 'package:agriguard_project/features/alerts/view/alert_details_screen.dart';
import 'package:agriguard_project/features/device_settings/view/device_settings_screen.dart';
import 'package:agriguard_project/features/profile/view/profile_screen.dart';
import 'soil_analysis_screen.dart';
import '../view_model/weather_details_screen.dart';
import 'package:agriguard_project/features/map/view/map_screen.dart';
import 'package:agriguard_project/features/chatbot/view/phone_capture_screen.dart';

// ─────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final String serial;
  const HomeScreen({super.key, required this.serial});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const String _baseUrl = 'https://robot-api-production.up.railway.app';
  static const Duration _pollInterval = Duration(seconds: 12);

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  int _selectedNavIndex = 2;

  // ── Live data ─────────────────────────────────────────────
  double? _soilTemperature;
  double? _soilMoisture;
  String? _soilStatus;
  List<GeneratedAlert> _liveAlerts = [];
  Timer? _pollTimer;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
    _fetchSoilData();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _fetchSoilData());
  }

  @override
  void dispose() {
    _animController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSoilData() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/soil/stream/latest'))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final snap = SoilSnapshot.fromJson(Map<String, dynamic>.from(data));
        final alerts = SoilAlertEngine.evaluate(snap);
        if (mounted) {
          setState(() {
            _soilTemperature = snap.reading.temperatureC;
            _soilMoisture = snap.reading.moisturePct;
            _soilStatus = snap.soilStatus;
            _liveAlerts = alerts;
            _dataLoaded = true;
          });
        }
      }
    } catch (_) {
      // Silently keep old data
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  int get _criticalCount =>
      _liveAlerts.where((a) => a.severity == AlertSeverity.critical).length;

  int get _totalAlerts =>
      _liveAlerts.where((a) => a.severity != AlertSeverity.info).length;

  GeneratedAlert? get _topAlert {
    final nonInfo =
        _liveAlerts.where((a) => a.severity != AlertSeverity.info).toList();
    return nonInfo.isEmpty ? null : nonInfo.first;
  }

  Color _tempColor(double t) {
    if (t < 8) return const Color(0xFF5B9BD5);
    if (t < 15) return const Color(0xFF70B77E);
    if (t < 30) return const Color(0xFF66785F); // using primary base color here to avoid passing context
    if (t < 36) return orangeColor;
    return redColor;
  }

  IconData _tempIcon(double t) {
    if (t < 10) return Icons.ac_unit_rounded;
    if (t < 28) return Icons.thermostat_rounded;
    return Icons.local_fire_department_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedNavIndex,
            children: [
              const MapScreen(),
              const AlertsScreen(),
              _buildDashboard(),
              DeviceSettingsScreen(serial: widget.serial),
              const ProfileScreen(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  DASHBOARD
  // ─────────────────────────────────────────────────────────

  Widget _buildDashboard() {
    return SafeArea(
      bottom: false,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeroHeader()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SizedBox(height: 20),
                  _buildLiveStatsRow(),
                  SizedBox(height: 20),
                  _buildAlertBanner(),
                  SizedBox(height: 24),
                  _buildSectionLabel('Quick Actions'),
                  SizedBox(height: 14),
                  _buildFeaturesGrid(),
                  SizedBox(height: 24),
                  _buildSectionLabel('Device Status'),
                  SizedBox(height: 14),
                  _buildDeviceStatusCard(),
                  SizedBox(height: 110),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HERO HEADER
  // ─────────────────────────────────────────────────────────

  Widget _buildHeroHeader() {
    String formattedSerial = widget.serial.isEmpty
        ? '122'
        : widget.serial.length > 6
            ? widget.serial.substring(0, 6).toUpperCase()
            : widget.serial.toUpperCase();

    // Greet by time of day
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor,
            theme.primaryColor.withAlpha(200),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onPrimary.withAlpha(15),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onPrimary.withAlpha(10),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo + Switch button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SvgPicture.asset(
                      'assets/app_images/icons/logo.svg',
                      height: 38,
                      colorFilter: ColorFilter.mode(
                          colorScheme.onPrimary, BlendMode.srcIn),
                      errorBuilder: (ctx, err, st) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco_rounded,
                              color: colorScheme.onPrimary, size: 26),
                          const SizedBox(width: 6),
                          Text(
                            'AGRIGUARD',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'AbhayaLibre',
                              fontSize: 18,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ScaleOnTap(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SelectDeviceScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: colorScheme.onPrimary.withAlpha(60), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz_rounded,
                                color: colorScheme.onPrimary, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Switch',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                fontFamily: 'AbhayaLibre',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Greeting
                Text(
                  greeting,
                  style: TextStyle(
                    color: colorScheme.onPrimary.withAlpha(180),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Device #$formattedSerial',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre',
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online & Transmitting',
                      style: TextStyle(
                        color: colorScheme.onPrimary.withAlpha(180),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  LIVE STATS ROW (Temperature + Moisture + Alerts)
  // ─────────────────────────────────────────────────────────

  Widget _buildLiveStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          icon: _dataLoaded && _soilTemperature != null
              ? _tempIcon(_soilTemperature!)
              : Icons.thermostat_rounded,
          iconColor: _dataLoaded && _soilTemperature != null
              ? _tempColor(_soilTemperature!)
              : grayColor,
          label: 'Soil Temp',
          value: _dataLoaded && _soilTemperature != null
              ? '${_soilTemperature!.toStringAsFixed(1)}°C'
              : '--',
          isLoading: !_dataLoaded,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SoilAnalysisScreen())),
        )),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          icon: Icons.water_drop_rounded,
          iconColor: const Color(0xFF5B9BD5),
          label: 'Moisture',
          value: _dataLoaded && _soilMoisture != null
              ? '${_soilMoisture!.toStringAsFixed(1)}%'
              : '--',
          isLoading: !_dataLoaded,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SoilAnalysisScreen())),
        )),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          icon: Icons.notifications_rounded,
          iconColor: _criticalCount > 0 ? redColor : (
              _totalAlerts > 0 ? orangeColor : Theme.of(context).primaryColor),
          label: 'Alerts',
          value: _dataLoaded ? '$_totalAlerts' : '--',
          isLoading: !_dataLoaded,
          badge: _criticalCount > 0 ? '$_criticalCount' : null,
          onTap: () => setState(() => _selectedNavIndex = 1),
        )),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isLoading,
    String? badge,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withAlpha(50), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 8),
              blurRadius: isDark ? 8 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: redColor,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: colorScheme.surface, width: 1.5),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (isLoading)
              Container(
                width: 40,
                height: 16,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            else
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                ),
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: grayColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ALERT BANNER (dynamic)
  // ─────────────────────────────────────────────────────────

  Widget _buildAlertBanner() {
    if (!_dataLoaded) return _buildAlertBannerSkeleton();

    final top = _topAlert;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Healthy state
    if (top == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A3A1A) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.primaryColor.withAlpha(60)),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withAlpha(isDark ? 25 : 12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified_rounded,
                  color: theme.primaryColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Systems Healthy',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Soil parameters are within optimal ranges.',
                    style: TextStyle(
                      color: grayColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Alert state
    final isCritical = top.severity == AlertSeverity.critical;
    final color = isCritical ? redColor : orangeColor;
    final bg = isCritical
        ? (isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEE))
        : (isDark ? const Color(0xFF3A2F1A) : const Color(0xFFFFF8E1));

    return ScaleOnTap(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlertDetailsScreen(alert: top),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(70), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(isDark ? 35 : 20),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(top.icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCritical ? 'CRITICAL' : 'WARNING',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      if (_totalAlerts > 1) ...[
                        const SizedBox(width: 6),
                        Text(
                          '+${_totalAlerts - 1} more',
                          style: const TextStyle(
                            color: grayColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    top.title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${top.paramName}: ${top.value.toStringAsFixed(top.value < 10 ? 2 : 1)} ${top.unit}',
                    style: const TextStyle(
                      color: grayColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: grayColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBannerSkeleton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 80,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? theme.colorScheme.onSurface.withAlpha(30) : Colors.grey.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(
                    height: 10,
                    width: 200,
                    decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SECTION LABEL
  // ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Text(
      label,
      style: theme.textTheme.displayMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        fontFamily: 'AbhayaLibre',
        letterSpacing: -0.3,
      ) ?? TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        fontFamily: 'AbhayaLibre',
        color: colorScheme.onSurface,
        letterSpacing: -0.3,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  FEATURES GRID
  // ─────────────────────────────────────────────────────────

  Widget _buildFeaturesGrid() {
    final items = [
      _GridItem(
        networkImage:
            'https://www.yarbo.com/cdn/shop/files/Yarbo_Robot_1_200kb.jpg?v=1781161297&width=1280',
        localImage: 'assets/app_images/images/location.png',
        title: 'Live Location',
        subtitle: 'Track robot GPS',
        icon: Icons.location_on_rounded,
        iconColor: Theme.of(context).primaryColor,
        onTap: () => setState(() => _selectedNavIndex = 0),
      ),
      _GridItem(
        networkImage:
            'https://agriconnutritech.com/wp-content/uploads/2024/08/hand-holding.webp',
        localImage: 'assets/app_images/images/soil.png',
        title: 'Soil Analysis',
        subtitle: 'Monitor nutrients',
        icon: Icons.grass_rounded,
        iconColor: Theme.of(context).primaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SoilAnalysisScreen()),
        ),
      ),
      _GridItem(
        networkImage:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRi3heGGlGC_n_bzu2bb85TEwuYzX7lsOvmWA&s',
        localImage: 'assets/app_images/images/camera.png',
        title: 'Phone Capture',
        subtitle: 'AI crop analysis',
        icon: Icons.camera_alt_rounded,
        iconColor: Theme.of(context).primaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PhoneCaptureScreen()),
        ),
      ),
      _GridItem(
        networkImage:
            'https://www.bigcountryhomepage.com/wp-content/uploads/sites/56/2019/06/Weather-v2.jpg?w=640',
        localImage: 'assets/app_images/images/weather.png',
        title: 'Weather',
        subtitle: 'Wind, humidity & rain',
        icon: Icons.cloud_rounded,
        iconColor: Theme.of(context).primaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WeatherDetailsScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (ctx, i) => _buildGridCard(items[i]),
    );
  }

  Widget _buildGridCard(_GridItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return ScaleOnTap(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 8),
              blurRadius: isDark ? 8 : 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Network image with local fallback
                    Image.network(
                      item.networkImage,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Image.asset(
                        item.localImage,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx2, err2, st2) => Container(
                          color: item.iconColor.withAlpha(20),
                          child: Center(
                            child: Icon(item.icon,
                                color: item.iconColor, size: 36),
                          ),
                        ),
                      ),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4F0),
                          child: Center(
                            child: Icon(item.icon,
                                color: item.iconColor.withAlpha(120), size: 36),
                          ),
                        );
                      },
                    ),
                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 50,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0x3C000000),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Icon badge top-left
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withAlpha(220),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon,
                            color: item.iconColor, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Text area
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: grayColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  DEVICE STATUS CARD
  // ─────────────────────────────────────────────────────────

  Widget _buildDeviceStatusCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final statusLabel = _soilStatus != null
        ? _soilStatus![0].toUpperCase() + _soilStatus!.substring(1)
        : 'Loading…';
    final statusColor = _soilStatus == null
        ? grayColor
        : _soilStatus == 'healthy'
            ? theme.primaryColor
            : _soilStatus == 'warning'
                ? orangeColor
                : redColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? colorScheme.onSurface.withAlpha(30) : Colors.grey.withAlpha(40), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 6),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.smart_toy_rounded,
                    color: theme.primaryColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AgriGuard Robot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'AbhayaLibre',
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Active & Transmitting',
                      style: TextStyle(
                        fontSize: 11,
                        color: grayColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Soil status pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withAlpha(60)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 16),
          // Battery row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusChip(
                  Icons.battery_charging_full_rounded, '70%', 'Battery', theme.primaryColor),
              _buildStatusChip(
                  Icons.sensors_rounded, 'ON', 'Sensors', const Color(0xFF4ADE80)),
              _buildStatusChip(
                  Icons.wifi_rounded, 'Live', 'Signal', const Color(0xFF5B9BD5)),
              _buildStatusChip(
                  Icons.thermostat_rounded,
                  _soilTemperature != null
                      ? '${_soilTemperature!.toStringAsFixed(0)}°'
                      : '--',
                  'Temp',
                  _soilTemperature != null
                      ? _tempColor(_soilTemperature!)
                      : grayColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
      IconData icon, String value, String label, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: grayColor,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  BOTTOM NAV BAR
  // ─────────────────────────────────────────────────────────

  Widget _buildBottomNavigationBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 72,
        decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withAlpha(isDark ? 50 : 90),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(
                  0, Icons.location_on_outlined, Icons.location_on_rounded),
              _buildNavItem(
                  1, Icons.warning_amber_outlined, Icons.warning_outlined,
                  badge: _criticalCount > 0 ? '$_criticalCount' : null),
              _buildFloatingHomeItem(2),
              _buildNavItem(
                  3, Icons.smart_toy_outlined, Icons.smart_toy_rounded),
              _buildNavItem(
                  4, Icons.person_outline_rounded, Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlined, IconData solid,
      {String? badge}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isSelected = _selectedNavIndex == index;
    return ScaleOnTap(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: SizedBox(
        height: 60,
        width: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                isSelected ? solid : outlined,
                key: ValueKey(isSelected),
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onPrimary.withAlpha(130),
                size: isSelected ? 28 : 24,
              ),
            ),
            if (badge != null)
              Positioned(
                top: 10,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: redColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.primaryColor, width: 1.5),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingHomeItem(int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bool isSelected = _selectedNavIndex == index;
    return ScaleOnTap(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 40 : 25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Icon(
            isSelected ? Icons.home_rounded : Icons.home_outlined,
            color: theme.primaryColor,
            size: 28,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DATA HELPERS
// ─────────────────────────────────────────────────────────────

class _GridItem {
  final String networkImage;
  final String localImage;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _GridItem({
    required this.networkImage,
    required this.localImage,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────
//  SCALE ON TAP
// ─────────────────────────────────────────────────────────────

class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const ScaleOnTap({super.key, required this.child, this.onTap});

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.onTap != null ? _controller.forward() : null,
      onTapUp: (_) {
        if (widget.onTap != null) {
          _controller.reverse();
          widget.onTap!();
        }
      },
      onTapCancel: () =>
          widget.onTap != null ? _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}