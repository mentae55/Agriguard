// lib/presentation/widgets/soil/gauges_grid.dart
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../data/model/soil_model.dart';
import '../../view_model/soil_analysis_viewmodel.dart';

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

class GaugesGrid extends StatelessWidget {
  final SoilAnalysisViewModel vm;
  final SoilSnapshot snap;
  const GaugesGrid({super.key, required this.vm, required this.snap});

  @override
  Widget build(BuildContext context) {
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
      itemBuilder: (context, i) => _GaugeCard(vm: vm, g: gauges[i]),
    );
  }
}

class _GaugeCard extends StatelessWidget {
  final SoilAnalysisViewModel vm;
  final _GaugeData g;

  const _GaugeCard({required this.vm, required this.g});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final alertColor = vm.alertColorForParam(g.paramKey);
    final isAlert = alertColor != null;
    final cardBorder = isAlert ? alertColor : Colors.transparent;
    final progress = ((g.value - g.min) / (g.max - g.min)).clamp(0.0, 1.0);
    final barColor = alertColor ?? primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: cardBorder.withAlpha(isAlert ? (isDark ? 160 : 100) : 0),
            width: 1.5),
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
}