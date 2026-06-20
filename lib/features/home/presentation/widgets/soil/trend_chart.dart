// lib/features/home/presentation/widgets/soil/trend_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../view_model/soil_analysis_viewmodel.dart';

class TrendsSection extends StatefulWidget {
  final SoilAnalysisViewModel vm;

  const TrendsSection({super.key, required this.vm});

  @override
  State<TrendsSection> createState() => _TrendsSectionState();
}

class _TrendsSectionState extends State<TrendsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<String> _params = [
    'moisture', 'ph', 'nitrogen', 'phosphorus',
    'potassium', 'temperature', 'ec', 'organic_matter',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _params.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vm.history.length < 2) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'Not enough data yet — check back after the next reading',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: _params
                  .map((p) => Tab(text: p.replaceAll('_', ' ').toUpperCase()))
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: TabBarView(
                controller: _tabController,
                children: _params.map((p) => _buildChart(p)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(String param) {
    final history = widget.vm.history;

    // Spec-correct safe ranges
    final range = SoilAnalysisViewModel.safeRanges[param] ?? [0.0, 100.0];

    final spots = <FlSpot>[];
    double minY = range[0];
    double maxY = range[1];

    for (int i = 0; i < history.length; i++) {
      final reading = history[i];
      if (reading.readings.containsKey(param)) {
        final val = reading.readings[param]!.value;
        spots.add(FlSpot(i.toDouble(), val));
        if (val < minY) minY = val;
        if (val > maxY) maxY = val;
      }
    }

    // Give some padding to Y axis
    final yPadding = (maxY - minY) * 0.2;
    minY -= yPadding;
    maxY += yPadding;

    // Prevent negative unless temperature
    if (minY < 0 && param != 'temperature') minY = 0;

    return Padding(
      padding: const EdgeInsets.only(right: 24.0, left: 8.0),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
          ),
          titlesData: FlTitlesData(
            topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= 0 && i < history.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('HH:mm').format(history[i].timestamp),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                interval:
                (history.length / 4).ceil().toDouble().clamp(1, 100),
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          // Dashed lines showing the safe range boundaries
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: range[0],
                color: Colors.green.withOpacity(0.5),
                strokeWidth: 2,
                dashArray: [5, 5],
              ),
              HorizontalLine(
                y: range[1],
                color: Colors.green.withOpacity(0.5),
                strokeWidth: 2,
                dashArray: [5, 5],
              ),
            ],
            extraLinesOnTop: false,
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}