import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:agriguard_project/core/core.dart';

// ═════════════════════════════════════════════
//  DATA MODELS
// ═════════════════════════════════════════════

class SoilReading {
  final String locationId;
  final String deviceId;
  final double moisturePct;
  final double ph;
  final double nitrogenPpm;
  final double phosphorusPpm;
  final double potassiumPpm;
  final double temperatureC;
  final double ecDsM;
  final double organicMatter;

  SoilReading({
    required this.locationId,
    required this.deviceId,
    required this.moisturePct,
    required this.ph,
    required this.nitrogenPpm,
    required this.phosphorusPpm,
    required this.potassiumPpm,
    required this.temperatureC,
    required this.ecDsM,
    required this.organicMatter,
  });

  factory SoilReading.fromJson(Map<String, dynamic> j) => SoilReading(
        locationId: j['location_id']?.toString() ?? '--',
        deviceId: j['device_id']?.toString() ?? '--',
        moisturePct: (j['moisture_pct'] as num?)?.toDouble() ?? 0.0,
        ph: (j['ph'] as num?)?.toDouble() ?? 0.0,
        nitrogenPpm: (j['nitrogen_ppm'] as num?)?.toDouble() ?? 0.0,
        phosphorusPpm: (j['phosphorus_ppm'] as num?)?.toDouble() ?? 0.0,
        potassiumPpm: (j['potassium_ppm'] as num?)?.toDouble() ?? 0.0,
        temperatureC: (j['temperature_c'] as num?)?.toDouble() ?? 0.0,
        ecDsM: (j['ec_ds_m'] as num?)?.toDouble() ?? 0.0,
        organicMatter: (j['organic_matter'] as num?)?.toDouble() ?? 0.0,
      );
}

class SoilAlert {
  final String param;
  final double value;
  final String unit;
  final String status;
  final String severity;
  final String recommendation;

  SoilAlert({
    required this.param,
    required this.value,
    required this.unit,
    required this.status,
    required this.severity,
    required this.recommendation,
  });

  factory SoilAlert.fromJson(Map<String, dynamic> j) => SoilAlert(
        param: j['param']?.toString() ?? '--',
        value: (j['value'] as num?)?.toDouble() ?? 0.0,
        unit: j['unit']?.toString() ?? '',
        status: j['status']?.toString() ?? '--',
        severity: j['severity']?.toString() ?? 'warning',
        recommendation: j['recommendation']?.toString() ?? '',
      );
}

class SoilSnapshot {
  final String soilStatus;
  final String timestamp;
  final int nAlerts;
  final String primaryAction;
  final double confidence;
  final SoilReading reading;
  final List<SoilAlert> alerts;

  SoilSnapshot({
    required this.soilStatus,
    required this.timestamp,
    required this.nAlerts,
    required this.primaryAction,
    required this.confidence,
    required this.reading,
    required this.alerts,
  });

  factory SoilSnapshot.fromJson(Map<String, dynamic> j) => SoilSnapshot(
        soilStatus: j['soil_status']?.toString() ?? 'unknown',
        timestamp: j['timestamp']?.toString() ?? '',
        nAlerts: (j['n_alerts'] as num?)?.toInt() ?? 0,
        primaryAction: j['primary_action']?.toString() ?? '--',
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0.0,
        reading: SoilReading.fromJson(
            Map<String, dynamic>.from(j['reading'] as Map? ?? {})),
        alerts: (j['alerts'] as List? ?? [])
            .map((a) =>
                SoilAlert.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList(),
      );
}

// ═════════════════════════════════════════════
//  GAUGE DATA HELPER
// ═════════════════════════════════════════════

class _GaugeData {
  final String name;
  final double value;
  final String unit;
  final double min;
  final double max;
  final String paramKey;
  final IconData icon;

  _GaugeData(this.name, this.value, this.unit, this.min, this.max,
      this.paramKey, this.icon);
}

// ═════════════════════════════════════════════
//  SCREEN
// ═════════════════════════════════════════════

class SoilAnalysisScreen extends StatefulWidget {
  const SoilAnalysisScreen({super.key});

  @override
  State<SoilAnalysisScreen> createState() => _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState extends State<SoilAnalysisScreen>
    with SingleTickerProviderStateMixin {
  static const String _baseUrl =
      'https://robot-api-production.up.railway.app';
  static const int _maxHistory = 20;
  static const Duration _pollInterval = Duration(seconds: 5);

  SoilSnapshot? _latest;
  final List<SoilSnapshot> _history = [];

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  Timer? _pollTimer;
  late AnimationController _pulseController;

  // ── Lifecycle ──────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initAndStartPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── API helpers ────────────────────────────

  Future<void> _initAndStartPolling() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // 1. Health check
      final health = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      if (health.statusCode != 200) {
        throw Exception('Server not ready (status ${health.statusCode})');
      }

      // 2. Start simulation stream
      await http
          .post(Uri.parse('$_baseUrl/soil/stream/start'),
              headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      // 3. First fetch
      await _fetchLatest();

      // 4. Start periodic polling every 5 seconds
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(_pollInterval, (_) => _fetchLatest());
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _fetchLatest() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/soil/stream/latest'))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final snap = SoilSnapshot.fromJson(
            Map<String, dynamic>.from(jsonDecode(res.body) as Map));
        if (mounted) {
          setState(() {
            _latest = snap;
            _history.add(snap);
            if (_history.length > _maxHistory) _history.removeAt(0);
            _isLoading = false;
            _hasError = false;
          });
        }
      }
    } catch (_) {
      // Silently keep old data on transient network errors
    }
  }

  // ── Helpers ────────────────────────────────

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green.shade600;
      case 'warning':
        return orangeColor;
      case 'critical':
        return redColor;
      default:
        return grayColor;
    }
  }

  Color _statusBg(String status, {bool isDark = false}) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return isDark ? const Color(0xFF1A3A1A) : const Color(0xFFF0FDF4);
      case 'warning':
        return isDark ? const Color(0xFF3A2F1A) : const Color(0xFFFFF8E1);
      case 'critical':
        return isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEE);
      default:
        return isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    }
  }

  String _formatTimestamp(String ts) {
    if (ts.isEmpty) return '--';
    try {
      final dt = DateTime.parse(ts);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, $h:$m';
    } catch (_) {
      return ts;
    }
  }

  String _formatParamName(String raw) {
    return raw
        .replaceAll('_ppm', '')
        .replaceAll('_pct', '')
        .replaceAll('_c', '')
        .replaceAll('_ds_m', '')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((w) =>
            w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Returns alert severity color for a given sensor param key, or null if clean.
  Color? _alertColorForParam(String paramKey) {
    if (_latest == null) return null;
    for (final a in _latest!.alerts) {
      if (a.param == paramKey) {
        return a.severity.toLowerCase() == 'critical'
            ? redColor
            : orangeColor;
      }
    }
    return null;
  }

  // ═════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.secondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_return_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Soil Analysis',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            fontSize: 24,
          ),
        ),
        actions: [
          // Live pulse indicator
          if (!_isLoading && !_hasError)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, _) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green
                          .withValues(alpha: 0.4 + 0.6 * _pulseController.value),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SvgPicture.asset(
              'assets/app_images/icons/logo.svg',
              width: width50,
              height: height48,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _hasError
              ? _buildError()
              : _buildContent(),
    );
  }

  // ── Loading state ──────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
          SizedBox(height: 20),
          Text(
            'Connecting to sensors...',
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

  // ── Error state ────────────────────────────

  Widget _buildError() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: redColor.withAlpha(60)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.sensors_off_rounded,
                      color: redColor, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Could not connect to sensors',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                      fontSize: 18,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: grayColor, fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _initAndStartPolling,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
                    Icon(Icons.refresh_rounded,
                        color: colorScheme.onPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Retry',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
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

  // ── Main scrollable content ────────────────

  Widget _buildContent() {
    final snap = _latest!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1 — Status Bar
          _buildStatusBar(snap),
          const SizedBox(height: 24),

          // Section 2 — Live Sensor Gauges
          _buildSectionHeader('Live Sensor Gauges', Icons.sensors_rounded),
          const SizedBox(height: 12),
          _buildGaugesGrid(snap),
          const SizedBox(height: 28),

          // Section 3 — Recommendation
          _buildSectionHeader(
              'AI Recommendation', Icons.lightbulb_outline_rounded),
          const SizedBox(height: 12),
          _buildRecommendationCard(snap),
          const SizedBox(height: 28),

          // Section 4 — Active Alerts
          _buildSectionHeader(
              'Active Alerts', Icons.warning_amber_rounded),
          const SizedBox(height: 12),
          _buildAlertsSection(snap),
          const SizedBox(height: 28),

          // Section 5 — Historical Trends
          _buildSectionHeader(
              'Historical Trends', Icons.show_chart_rounded),
          const SizedBox(height: 12),
          _buildTrendsSection(),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  SECTION HEADER
  // ═════════════════════════════════════════════

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════
  //  SECTION 1 — STATUS BAR
  // ═════════════════════════════════════════════

  Widget _buildStatusBar(SoilSnapshot snap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final sc = _statusColor(snap.soilStatus);
    final sb = _statusBg(snap.soilStatus, isDark: isDark);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sc.withAlpha(60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 5),
            blurRadius: isDark ? 8 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sb,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sc.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: sc, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      snap.soilStatus.toUpperCase(),
                      style: TextStyle(
                        color: sc,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        fontFamily: 'AbhayaLibre',
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Timestamp
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: grayColor),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(snap.timestamp),
                    style: const TextStyle(
                      color: grayColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(Icons.location_on_outlined, 'Field',
                    snap.reading.locationId),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoChip(Icons.memory_rounded, 'Device',
                    snap.reading.deviceId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.onSurface.withAlpha(15) : const Color(0xFFF5F8F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: grayColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
                Text(value,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'AbhayaLibre',
                    ),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  SECTION 2 — LIVE SENSOR GAUGES
  // ═════════════════════════════════════════════

  Widget _buildGaugesGrid(SoilSnapshot snap) {
    final gauges = [
      _GaugeData('Moisture', snap.reading.moisturePct, '%', 15, 50,
          'moisture_pct', Icons.water_drop_outlined),
      _GaugeData('pH', snap.reading.ph, '', 5.5, 7.8, 'ph',
          Icons.science_outlined),
      _GaugeData('Nitrogen', snap.reading.nitrogenPpm, 'ppm', 10, 70,
          'nitrogen_ppm', Icons.grass_outlined),
      _GaugeData('Phosphorus', snap.reading.phosphorusPpm, 'ppm', 5, 60,
          'phosphorus_ppm', Icons.blur_circular_outlined),
      _GaugeData('Potassium', snap.reading.potassiumPpm, 'ppm', 50, 300,
          'potassium_ppm', Icons.local_florist_outlined),
      _GaugeData('Temperature', snap.reading.temperatureC, '°C', 8, 38,
          'temperature_c', Icons.thermostat_outlined),
      _GaugeData('EC', snap.reading.ecDsM, 'dS/m', 0.3, 3.0, 'ec_ds_m',
          Icons.electric_bolt_outlined),
      _GaugeData('Organic Matter', snap.reading.organicMatter, '%', 1.0,
          6.5, 'organic_matter', Icons.eco_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: gauges.length,
      itemBuilder: (context, i) => _buildGaugeCard(gauges[i]),
    );
  }

  Widget _buildGaugeCard(_GaugeData g) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final alertColor = _alertColorForParam(g.paramKey);
    final isAlert = alertColor != null;
    final cardBorder = isAlert ? alertColor : Colors.transparent;

    // Progress within safe range (clamped 0–1)
    final progress = ((g.value - g.min) / (g.max - g.min)).clamp(0.0, 1.0);
    final barColor = alertColor ?? primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: cardBorder.withAlpha(isAlert ? (isDark ? 160 : 100) : 0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 5),
            blurRadius: isDark ? 8 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(g.icon, size: 14, color: grayColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        g.name,
                        style: const TextStyle(
                          color: grayColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAlert)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: alertColor, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                g.value.toStringAsFixed(g.value < 10 ? 2 : 1),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                  color: colorScheme.onSurface,
                ),
              ),
              if (g.unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(g.unit,
                      style: const TextStyle(
                          color: grayColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: barColor.withAlpha(isDark ? 45 : 30),
              color: barColor,
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${g.min} – ${g.max} ${g.unit}',
            style: const TextStyle(
                color: grayColor, fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  SECTION 3 — RECOMMENDATION CARD
  // ═════════════════════════════════════════════

  Widget _buildRecommendationCard(SoilSnapshot snap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final sc = _statusColor(snap.soilStatus);
    final sb = _statusBg(snap.soilStatus, isDark: isDark);
    final pct = (snap.confidence * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: sb,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sc.withAlpha(60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: sc.withAlpha(isDark ? 35 : 20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sc.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.agriculture_rounded,
                    color: sc, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Action',
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(160),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: sc.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pct% confidence',
                        style: TextStyle(
                          color: sc,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            snap.primaryAction,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFamily: 'AbhayaLibre',
              color: colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  SECTION 4 — ACTIVE ALERTS
  // ═════════════════════════════════════════════

  Widget _buildAlertsSection(SoilSnapshot snap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    if (snap.nAlerts == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A3A1A) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark ? Colors.green.withAlpha(90) : Colors.green.shade300.withAlpha(100), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.green, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '✅ Soil is healthy — no active alerts.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: snap.alerts
          .map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAlertCard(a),
              ))
          .toList(),
    );
  }

  Widget _buildAlertCard(SoilAlert a) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isCritical = a.severity.toLowerCase() == 'critical';
    final sevColor = isCritical ? redColor : orangeColor;
    final sevBg =
        isCritical
            ? (isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEE))
            : (isDark ? const Color(0xFF3A2F1A) : const Color(0xFFFFF8E1));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sevColor.withAlpha(isDark ? 90 : 60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 5),
            blurRadius: isDark ? 8 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCritical
                    ? Icons.error_outline_rounded
                    : Icons.warning_amber_rounded,
                color: sevColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatParamName(a.param),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre',
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              // Severity badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sevBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sevColor.withAlpha(80)),
                ),
                child: Text(
                  a.severity.toUpperCase(),
                  style: TextStyle(
                    color: sevColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Value + status row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.onSurface.withAlpha(15) : const Color(0xFFF5F8F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${a.value} ${a.unit}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'AbhayaLibre',
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sevColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  a.status.toUpperCase(),
                  style: TextStyle(
                    color: sevColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            a.recommendation,
            style: TextStyle(
              color: colorScheme.onSurface.withAlpha(180),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  SECTION 5 — HISTORICAL TREND CHARTS
  // ═════════════════════════════════════════════

  Widget _buildTrendsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    if (_history.length < 2) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 5),
              blurRadius: isDark ? 8 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: primaryColor, strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              const Text(
                'Collecting data for trends...',
                style: TextStyle(
                  color: grayColor,
                  fontFamily: 'AbhayaLibre',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildLineChart(
          title: 'Moisture (%)',
          color: Colors.blue.shade400,
          values:
              _history.map((s) => s.reading.moisturePct).toList(),
          safeMin: 15,
          safeMax: 50,
        ),
        const SizedBox(height: 16),
        _buildLineChart(
          title: 'pH',
          color: Colors.purple.shade400,
          values: _history.map((s) => s.reading.ph).toList(),
          safeMin: 5.5,
          safeMax: 7.8,
        ),
        const SizedBox(height: 16),
        _buildNPKChart(),
        const SizedBox(height: 16),
        _buildLineChart(
          title: 'Temperature (°C)',
          color: Colors.orange.shade400,
          values:
              _history.map((s) => s.reading.temperatureC).toList(),
          safeMin: 8,
          safeMax: 38,
        ),
        const SizedBox(height: 16),
        _buildLineChart(
          title: 'EC (dS/m)',
          color: Colors.teal.shade400,
          values: _history.map((s) => s.reading.ecDsM).toList(),
          safeMin: 0.3,
          safeMax: 3.0,
        ),
      ],
    );
  }

  Widget _buildLineChart({
    required String title,
    required Color color,
    required List<double> values,
    required double safeMin,
    required double safeMax,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 5),
            blurRadius: isDark ? 8 : 10,
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
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                values.last.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'AbhayaLibre',
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _LinePainter(
                values: values,
                color: color,
                safeMin: safeMin,
                safeMax: safeMax,
                surfaceColor: colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNPKChart() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 5),
            blurRadius: isDark ? 8 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NPK (ppm)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontFamily: 'AbhayaLibre',
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            children: [
              _legend('N', Colors.green.shade600),
              const SizedBox(width: 12),
              _legend('P', Colors.blue.shade400),
              const SizedBox(width: 12),
              _legend('K', Colors.orange.shade400),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _NPKPainter(history: _history),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: grayColor,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ═════════════════════════════════════════════
//  CUSTOM PAINTERS
// ═════════════════════════════════════════════

class _LinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double safeMin;
  final double safeMax;
  final Color surfaceColor;

  _LinePainter({
    required this.values,
    required this.color,
    required this.safeMin,
    required this.safeMax,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    // Compute y-axis range from data + safe bounds
    double dataMin = values.reduce(math.min);
    double dataMax = values.reduce(math.max);
    final rangeMin = math.min(dataMin, safeMin) - 1;
    final rangeMax = math.max(dataMax, safeMax) + 1;
    final range = (rangeMax - rangeMin).clamp(0.001, double.infinity);

    double toY(double v) =>
        size.height - ((v - rangeMin) / range * size.height);

    // Safe range band
    final bandPaint = Paint()
      ..color = color.withAlpha(18)
      ..style = PaintingStyle.fill;
    final bandTop = toY(safeMax);
    final bandBottom = toY(safeMin);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, bandTop, size.width, bandBottom),
        const Radius.circular(4),
      ),
      bandPaint,
    );

    // Safe range dashed border lines
    final dashPaint = Paint()
      ..color = color.withAlpha(40)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(0, bandTop), Offset(size.width, bandTop), dashPaint);
    canvas.drawLine(
        Offset(0, bandBottom), Offset(size.width, bandBottom), dashPaint);

    // Gradient fill under the line
    final step = size.width / (values.length - 1);
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (int i = 0; i < values.length; i++) {
      fillPath.lineTo(i * step, toY(values[i]));
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(40), color.withAlpha(5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Main line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * step;
      final y = toY(values[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < values.length; i++) {
      final offset = Offset(i * step, toY(values[i]));
      canvas.drawCircle(offset, 3.5, dotBorderPaint);
      canvas.drawCircle(offset, 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values.length != values.length ||
      (values.isNotEmpty && old.values.last != values.last);
}

class _NPKPainter extends CustomPainter {
  final List<SoilSnapshot> history;

  _NPKPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    final nValues = history.map((s) => s.reading.nitrogenPpm).toList();
    final pValues = history.map((s) => s.reading.phosphorusPpm).toList();
    final kValues = history.map((s) => s.reading.potassiumPpm).toList();

    // Compute shared y-axis range
    final allValues = [...nValues, ...pValues, ...kValues];
    final dataMin = allValues.reduce(math.min);
    final dataMax = allValues.reduce(math.max);
    final rangeMin = dataMin - 5;
    final rangeMax = dataMax + 5;
    final range = (rangeMax - rangeMin).clamp(0.001, double.infinity);

    double toY(double v) =>
        size.height - ((v - rangeMin) / range * size.height);

    final step = size.width / (history.length - 1);

    void drawLine(List<double> vals, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final path = Path();
      for (int i = 0; i < vals.length; i++) {
        final x = i * step;
        final y = toY(vals[i]);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);

      // End dot only (cleaner for multi-line chart)
      if (vals.isNotEmpty) {
        final lastX = (vals.length - 1) * step;
        canvas.drawCircle(Offset(lastX, toY(vals.last)), 3, dotPaint);
      }
    }

    drawLine(nValues, Colors.green.shade600);
    drawLine(pValues, Colors.blue.shade400);
    drawLine(kValues, Colors.orange.shade400);
  }

  @override
  bool shouldRepaint(covariant _NPKPainter old) =>
      old.history.length != history.length;
}
