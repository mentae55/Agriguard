import 'package:flutter/material.dart';
import '../../home/data/model/soil_model.dart';
import 'alert_model.dart';

class SoilAlertEngine {
  static List<GeneratedAlert> evaluate(SoilSnapshot snap) {
    final alerts = <GeneratedAlert>[];
    final now = DateTime.now();
    final r = snap.reading;

    // ── Moisture ─────────────────────────────────────────────
    if (r.moisturePct < 20) {
      alerts.add(GeneratedAlert(
        id: 'moisture_critical',
        title: 'Critical Moisture Deficit',
        description:
        'Soil moisture is at \${r.moisturePct.toStringAsFixed(1)}% — well below the safe minimum of 20%. '
            'Crops are at risk of severe water stress.',
        severity: AlertSeverity.critical,
        paramName: 'Moisture',
        value: r.moisturePct,
        unit: '%',
        recommendation:
        'Activate irrigation immediately. Target soil moisture between 30–40%. '
            'Inspect irrigation lines for blockages and re-scan in 2 hours.',
        icon: Icons.water_drop_rounded,
        timestamp: now,
      ));
    } else if (r.moisturePct < 28) {
      alerts.add(GeneratedAlert(
        id: 'moisture_warning',
        title: 'Low Soil Moisture',
        description:
        'Soil moisture is at \${r.moisturePct.toStringAsFixed(1)}%. '
            'Approaching the lower threshold — schedule irrigation soon.',
        severity: AlertSeverity.warning,
        paramName: 'Moisture',
        value: r.moisturePct,
        unit: '%',
        recommendation:
        'Schedule irrigation within the next 6 hours. '
            'Monitor conditions hourly.',
        icon: Icons.water_drop_rounded,
        timestamp: now,
      ));
    } else if (r.moisturePct > 55) {
      alerts.add(GeneratedAlert(
        id: 'moisture_high',
        title: 'Excess Soil Moisture',
        description:
        'Soil moisture is at \${r.moisturePct.toStringAsFixed(1)}% — risk of waterlogging and root rot.',
        severity: AlertSeverity.warning,
        paramName: 'Moisture',
        value: r.moisturePct,
        unit: '%',
        recommendation:
        'Pause irrigation. Inspect drainage channels. '
            'Consider aeration if moisture remains high for 24 hours.',
        icon: Icons.water_drop_rounded,
        timestamp: now,
      ));
    }

    // ── pH ────────────────────────────────────────────────────
    if (r.ph < 5.0) {
      alerts.add(GeneratedAlert(
        id: 'ph_critical_low',
        title: 'Severe Soil Acidification',
        description:
        'Soil pH is \${r.ph.toStringAsFixed(2)} — dangerously acidic. '
            'Nutrient availability is severely restricted.',
        severity: AlertSeverity.critical,
        paramName: 'pH',
        value: r.ph,
        unit: '',
        recommendation:
        'Apply agricultural lime (CaCO₃) at 2–3 t/ha. '
            'Re-test pH in 2 weeks. Avoid acid-forming fertilisers until corrected.',
        icon: Icons.science_rounded,
        timestamp: now,
      ));
    } else if (r.ph < 5.8) {
      alerts.add(GeneratedAlert(
        id: 'ph_warning_low',
        title: 'Acidic Soil Detected',
        description:
        'Soil pH is \${r.ph.toStringAsFixed(2)}. Slightly acidic; some nutrients may be less available.',
        severity: AlertSeverity.warning,
        paramName: 'pH',
        value: r.ph,
        unit: '',
        recommendation:
        'Consider light liming. Optimal pH range is 6.0–7.0. '
            'Monitor monthly.',
        icon: Icons.science_rounded,
        timestamp: now,
      ));
    } else if (r.ph > 8.0) {
      alerts.add(GeneratedAlert(
        id: 'ph_critical_high',
        title: 'Alkaline Soil Imbalance',
        description:
        'Soil pH is \${r.ph.toStringAsFixed(2)} — alkaline conditions reduce iron and zinc uptake.',
        severity: AlertSeverity.critical,
        paramName: 'pH',
        value: r.ph,
        unit: '',
        recommendation:
        'Apply elemental sulfur or acidifying fertiliser. '
            'Increase organic matter to buffer pH. Re-test in 3 weeks.',
        icon: Icons.science_rounded,
        timestamp: now,
      ));
    } else if (r.ph > 7.5) {
      alerts.add(GeneratedAlert(
        id: 'ph_warning_high',
        title: 'Mildly Alkaline Soil',
        description:
        'Soil pH is \${r.ph.toStringAsFixed(2)}. Slightly above optimal for most crops.',
        severity: AlertSeverity.warning,
        paramName: 'pH',
        value: r.ph,
        unit: '',
        recommendation:
        'Incorporate compost or peat moss. Monitor trend over next 30 days.',
        icon: Icons.science_rounded,
        timestamp: now,
      ));
    }

    // ── Nitrogen ──────────────────────────────────────────────
    if (r.nitrogenPpm < 15) {
      alerts.add(GeneratedAlert(
        id: 'nitrogen_critical',
        title: 'Critical Nitrogen Deficiency',
        description:
        'Nitrogen is at \${r.nitrogenPpm.toStringAsFixed(1)} ppm — critically low. '
            'Expect yellowing leaves and stunted growth.',
        severity: AlertSeverity.critical,
        paramName: 'Nitrogen',
        value: r.nitrogenPpm,
        unit: 'ppm',
        recommendation:
        'Apply urea (46-0-0) or ammonium nitrate immediately at 50–80 kg/ha. '
            'Supplement with foliar nitrogen spray. Re-scan in 5 days.',
        icon: Icons.grass_rounded,
        timestamp: now,
      ));
    } else if (r.nitrogenPpm < 25) {
      alerts.add(GeneratedAlert(
        id: 'nitrogen_warning',
        title: 'Low Nitrogen Level',
        description:
        'Nitrogen is at \${r.nitrogenPpm.toStringAsFixed(1)} ppm. '
            'Below recommended range of 25–60 ppm.',
        severity: AlertSeverity.warning,
        paramName: 'Nitrogen',
        value: r.nitrogenPpm,
        unit: 'ppm',
        recommendation:
        'Schedule nitrogen top-dressing within the week. '
            'Consider slow-release nitrogen sources.',
        icon: Icons.grass_rounded,
        timestamp: now,
      ));
    }

    // ── Phosphorus ────────────────────────────────────────────
    if (r.phosphorusPpm < 8) {
      alerts.add(GeneratedAlert(
        id: 'phosphorus_critical',
        title: 'Phosphorus Deficiency',
        description:
        'Phosphorus is at \${r.phosphorusPpm.toStringAsFixed(1)} ppm — critically low. '
            'Root development and flowering will be impaired.',
        severity: AlertSeverity.critical,
        paramName: 'Phosphorus',
        value: r.phosphorusPpm,
        unit: 'ppm',
        recommendation:
        'Apply DAP (18-46-0) fertiliser at 40–60 kg/ha. '
            'Ensure pH is corrected first for optimal phosphorus uptake.',
        icon: Icons.blur_circular_rounded,
        timestamp: now,
      ));
    } else if (r.phosphorusPpm < 15) {
      alerts.add(GeneratedAlert(
        id: 'phosphorus_warning',
        title: 'Low Phosphorus',
        description:
        'Phosphorus is at \${r.phosphorusPpm.toStringAsFixed(1)} ppm. '
            'Below optimal range.',
        severity: AlertSeverity.warning,
        paramName: 'Phosphorus',
        value: r.phosphorusPpm,
        unit: 'ppm',
        recommendation:
        'Schedule phosphate fertilisation. Monitor root health.',
        icon: Icons.blur_circular_rounded,
        timestamp: now,
      ));
    }

    // ── Potassium ─────────────────────────────────────────────
    if (r.potassiumPpm < 60) {
      alerts.add(GeneratedAlert(
        id: 'potassium_critical',
        title: 'Critical Potassium Shortage',
        description:
        'Potassium is at \${r.potassiumPpm.toStringAsFixed(0)} ppm — critically low. '
            'Fruit quality and disease resistance will suffer.',
        severity: AlertSeverity.critical,
        paramName: 'Potassium',
        value: r.potassiumPpm,
        unit: 'ppm',
        recommendation:
        'Apply potassium chloride (MOP) or potassium sulfate at 80–100 kg/ha.',
        icon: Icons.local_florist_rounded,
        timestamp: now,
      ));
    } else if (r.potassiumPpm < 100) {
      alerts.add(GeneratedAlert(
        id: 'potassium_warning',
        title: 'Low Potassium',
        description:
        'Potassium is at \${r.potassiumPpm.toStringAsFixed(0)} ppm. Below the 100 ppm baseline.',
        severity: AlertSeverity.warning,
        paramName: 'Potassium',
        value: r.potassiumPpm,
        unit: 'ppm',
        recommendation: 'Apply potassium fertiliser at the next scheduled application.',
        icon: Icons.local_florist_rounded,
        timestamp: now,
      ));
    }

    // ── Temperature ───────────────────────────────────────────
    if (r.temperatureC > 38) {
      alerts.add(GeneratedAlert(
        id: 'temperature_critical_high',
        title: 'Extreme Soil Heat',
        description:
        'Soil temperature is \${r.temperatureC.toStringAsFixed(1)}°C — extreme heat '
            'can denature soil enzymes and damage roots.',
        severity: AlertSeverity.critical,
        paramName: 'Temperature',
        value: r.temperatureC,
        unit: '°C',
        recommendation:
        'Apply mulch layer (5–8 cm) to insulate soil. Irrigate to reduce temperature. '
            'Consider shade netting if above-crop temperature is also high.',
        icon: Icons.thermostat_rounded,
        timestamp: now,
      ));
    } else if (r.temperatureC > 33) {
      alerts.add(GeneratedAlert(
        id: 'temperature_warning_high',
        title: 'High Soil Temperature',
        description:
        'Soil temperature is \${r.temperatureC.toStringAsFixed(1)}°C — above optimal range for most crops.',
        severity: AlertSeverity.warning,
        paramName: 'Temperature',
        value: r.temperatureC,
        unit: '°C',
        recommendation: 'Monitor closely. Consider early-morning irrigation to cool soil.',
        icon: Icons.thermostat_rounded,
        timestamp: now,
      ));
    } else if (r.temperatureC < 8) {
      alerts.add(GeneratedAlert(
        id: 'temperature_critical_low',
        title: 'Frost Risk Detected',
        description:
        'Soil temperature is \${r.temperatureC.toStringAsFixed(1)}°C — near-freezing conditions '
            'may halt germination and damage roots.',
        severity: AlertSeverity.critical,
        paramName: 'Temperature',
        value: r.temperatureC,
        unit: '°C',
        recommendation:
        'Apply frost protection covers. Avoid irrigation (ice formation risk). '
            'Monitor daily until temperature stabilises above 10°C.',
        icon: Icons.thermostat_rounded,
        timestamp: now,
      ));
    }

    // ── EC (Salinity) ─────────────────────────────────────────
    if (r.ecDsM > 3.0) {
      alerts.add(GeneratedAlert(
        id: 'ec_critical',
        title: 'Toxic Salinity Level',
        description:
        'Electrical conductivity is \${r.ecDsM.toStringAsFixed(2)} dS/m — toxic to most crops. '
            'Osmotic stress will severely limit water uptake.',
        severity: AlertSeverity.critical,
        paramName: 'Salinity (EC)',
        value: r.ecDsM,
        unit: 'dS/m',
        recommendation:
        'Apply heavy leaching irrigation to flush salts. '
            'Add gypsum (CaSO₄) to improve sodium displacement. '
            'Avoid saline water sources. Consider salt-tolerant cultivars.',
        icon: Icons.electric_bolt_rounded,
        timestamp: now,
      ));
    } else if (r.ecDsM > 2.0) {
      alerts.add(GeneratedAlert(
        id: 'ec_warning',
        title: 'Elevated Soil Salinity',
        description:
        'EC is at \${r.ecDsM.toStringAsFixed(2)} dS/m — salt stress may affect sensitive crops.',
        severity: AlertSeverity.warning,
        paramName: 'Salinity (EC)',
        value: r.ecDsM,
        unit: 'dS/m',
        recommendation:
        'Reduce fertiliser application. Apply leaching irrigation. Monitor weekly.',
        icon: Icons.electric_bolt_rounded,
        timestamp: now,
      ));
    }

    // ── Organic Matter ────────────────────────────────────────
    if (r.organicMatter < 1.5) {
      alerts.add(GeneratedAlert(
        id: 'om_critical',
        title: 'Very Low Organic Matter',
        description:
        'Organic matter is at \${r.organicMatter.toStringAsFixed(1)}% — '
            'soil structure and microbial activity are severely depleted.',
        severity: AlertSeverity.critical,
        paramName: 'Organic Matter',
        value: r.organicMatter,
        unit: '%',
        recommendation:
        'Incorporate 10–15 t/ha of compost or manure. '
            'Consider cover cropping and reduced tillage program.',
        icon: Icons.eco_rounded,
        timestamp: now,
      ));
    } else if (r.organicMatter < 2.5) {
      alerts.add(GeneratedAlert(
        id: 'om_warning',
        title: 'Low Organic Matter',
        description:
        'Organic matter is at \${r.organicMatter.toStringAsFixed(1)}%. '
            'Below the 2.5% minimum recommended for productive soil.',
        severity: AlertSeverity.warning,
        paramName: 'Organic Matter',
        value: r.organicMatter,
        unit: '%',
        recommendation:
        'Add compost or green manure at the next cultivation cycle.',
        icon: Icons.eco_rounded,
        timestamp: now,
      ));
    }

    // ── API alerts (pass-through from backend) ─────────────────
    for (final a in snap.alerts) {
      final alreadyCovered = alerts.any((g) =>
          g.paramName.toLowerCase().contains(a.param.split('_').first.toLowerCase()));
      if (!alreadyCovered) {
        alerts.add(GeneratedAlert(
          id: 'api_\${a.param}',
          title: _formatParamName(a.param),
          description: '\${_formatParamName(a.param)}: \${a.value.toStringAsFixed(2)} \${a.unit} — \${a.status}',
          severity: a.severity.toLowerCase() == 'critical'
              ? AlertSeverity.critical
              : AlertSeverity.warning,
          paramName: _formatParamName(a.param),
          value: a.value,
          unit: a.unit,
          recommendation: a.recommendation,
          icon: Icons.sensors_rounded,
          timestamp: DateTime.now(),
        ));
      }
    }

    // ── Healthy status info card ───────────────────────────────
    if (alerts.isEmpty) {
      alerts.add(GeneratedAlert(
        id: 'healthy',
        title: 'All Systems Healthy',
        description:
        'All soil parameters are within optimal ranges. '
            'Your field is in excellent condition.',
        severity: AlertSeverity.info,
        paramName: 'All Parameters',
        value: 0,
        unit: '',
        recommendation:
        'Continue current irrigation and fertilisation schedule. '
            'Next recommended scan in 24 hours.',
        icon: Icons.check_circle_rounded,
        timestamp: DateTime.now(),
      ));
    }

    alerts.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return alerts;
  }

  static String _formatParamName(String raw) {
    return raw
        .replaceAll('_ppm', '')
        .replaceAll('_pct', '')
        .replaceAll('_c', '')
        .replaceAll('_ds_m', '')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((w) => w.isEmpty ? '' : '\${w[0].toUpperCase()}\${w.substring(1)}')
        .join(' ');
  }
}