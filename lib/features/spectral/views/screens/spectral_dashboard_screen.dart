import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:agriguard_project/core/constants/app_colors.dart';
import '../../data/models/spectral_prediction.dart';
import '../../viewmodels/spectral_view_model.dart';
import '../../data/models/spectral_reading.dart';

class SpectralDashboardScreen extends StatefulWidget {
  const SpectralDashboardScreen({super.key});

  @override
  State<SpectralDashboardScreen> createState() => _SpectralDashboardScreenState();
}

class _SpectralDashboardScreenState extends State<SpectralDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpectralViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SpectralViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.secondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Spectral Disease Detection',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryColor),
            onPressed: () => vm.refresh(),
          ),
        ],
      ),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, SpectralViewModel vm) {
    if (vm.state == SpectralState.idle ||
        (vm.state == SpectralState.loading && vm.reading == null)) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text('Analyzing spectral data...', style: TextStyle(color: grayColor)),
          ],
        ),
      );
    }

    if (vm.state == SpectralState.error && vm.reading == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(vm.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vm.refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final reading = vm.reading;
    if (reading == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: vm.refresh,
      color: primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vm.state == SpectralState.error)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ Connection lost. Showing last known data.',
                        style: TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            _StatusBar(reading: reading),
            const SizedBox(height: 16),
            _RiskGaugeCard(reading: reading),
            const SizedBox(height: 16),
            _DetectionResultCard(reading: reading),
            const SizedBox(height: 16),
            if (reading.riskLevel != 'NONE' && reading.actions.isNotEmpty)
              _RecommendationCard(
                actions: reading.actions,
                riskLevel: reading.riskLevel,
              )
            else
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(Icons.spa_outlined, color: Colors.green, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No recommendations needed — your plant is looking great!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _TrendChartsSection(vm: vm),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Bar
// ---------------------------------------------------------------------------

class _StatusBar extends StatelessWidget {
  final SpectralPrediction reading;

  const _StatusBar({required this.reading});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    switch (reading.riskLevel.toUpperCase()) {
      case 'HIGH':
        badgeColor = Colors.red.shade700;
        break;
      case 'MEDIUM':
        badgeColor = Colors.orange.shade600;
        break;
      case 'LOW':
      case 'NONE':
      default:
        badgeColor = Colors.green.shade600;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                    BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    reading.riskLevel.toUpperCase(),
                    style: TextStyle(
                        color: badgeColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Text(
              'Last scan: ${DateFormat('HH:mm').format(reading.timestamp)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Risk Gauge
// ---------------------------------------------------------------------------

class _RiskGaugeCard extends StatelessWidget {
  final SpectralPrediction reading;

  const _RiskGaugeCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    Color gaugeColor;
    switch (reading.riskLevel.toUpperCase()) {
      case 'HIGH':
        gaugeColor = Colors.red.shade700;
        break;
      case 'MEDIUM':
        gaugeColor = Colors.orange.shade600;
        break;
      case 'LOW':
      case 'NONE':
      default:
        gaugeColor = Colors.green.shade600;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            const Text(
              'Disease Risk',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'AbhayaLibre'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              width: 150,
              child: CustomPaint(
                painter: _ArcGaugePainter(
                    color: gaugeColor, value: reading.riskProbability),
                child: Center(
                  child: Text(
                    '${(reading.riskProbability * 100).toInt()}%',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: gaugeColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${reading.riskLevel.toUpperCase()} RISK',
              style: TextStyle(
                  color: gaugeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final Color color;
  final double value;

  _ArcGaugePainter({required this.color, required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    const startAngle = 3 * pi / 4;
    const sweepAngle = 3 * pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * value.clamp(0.0, 1.0),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.value != value;
}

// ---------------------------------------------------------------------------
// Detection Result
// ---------------------------------------------------------------------------

class _DetectionResultCard extends StatelessWidget {
  final SpectralPrediction reading;

  const _DetectionResultCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    if (reading.riskLevel.toUpperCase() == 'NONE') {
      return Card(
        color: Colors.green.shade50,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.green.shade300),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  '✅ Plant appears healthy',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    String clusterIcon = '';
    if (reading.predictedGroup?.contains('Fungal') == true) {
      clusterIcon = '🍄';
    } else if (reading.predictedGroup?.contains('Pest') == true ||
        reading.predictedGroup?.contains('Bacterial') == true) {
      clusterIcon = '🐛';
    } else if (reading.predictedGroup?.contains('Viral') == true) {
      clusterIcon = '🦠';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detection Result',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'AbhayaLibre'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$clusterIcon ${reading.predictedGroup ?? 'Unknown'}',
                        style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        reading.likelyDisease?.replaceAll('_', ' ') ??
                            'Unknown',
                        style: const TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: reading.diseaseConfidence,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: primaryColor,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(reading.diseaseConfidence * 100).toInt()}% confidence',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recommendation / Action Plan
// ---------------------------------------------------------------------------

class _RecommendationCard extends StatelessWidget {
  final List<String> actions;
  final String riskLevel;

  const _RecommendationCard({
    required this.actions,
    required this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    Color urgencyColor;
    switch (riskLevel.toUpperCase()) {
      case 'HIGH':
        urgencyColor = Colors.red.shade700;
        break;
      case 'MEDIUM':
        urgencyColor = Colors.orange.shade600;
        break;
      case 'LOW':
      default:
        urgencyColor = Colors.green.shade600;
        break;
    }

    final primaryAction = actions.isNotEmpty ? actions.first : '';
    final secondaryActions = actions.length > 1 ? actions.sublist(1) : <String>[];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Action Plan',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'AbhayaLibre'),
                    ),
                  ],
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${riskLevel.toUpperCase()} URGENCY',
                    style: TextStyle(
                        color: urgencyColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              primaryAction,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: primaryColor),
            ),
            if (secondaryActions.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...secondaryActions.map(
                    (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold)),
                      Expanded(child: Text(action)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend Charts (risk probability only)
// ---------------------------------------------------------------------------

class _TrendChartsSection extends StatelessWidget {
  final SpectralViewModel vm;

  const _TrendChartsSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.history.length < 2) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'Not enough data yet — check back after the next reading',
              textAlign: TextAlign.center,
              style:
              TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );
    }

    final riskSpots = <FlSpot>[
      for (int i = 0; i < vm.history.length; i++)
        FlSpot(i.toDouble(), vm.history[i].riskProbability),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trend (last 20 scans)',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'AbhayaLibre'),
            ),
            const SizedBox(height: 16),
            const Text('Disease Risk Probability',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: riskSpots,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.2),
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
}