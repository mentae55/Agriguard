// lib/presentation/widgets/weather/hourly_forecast.dart
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../view_model/weather_viewmodel.dart';

class HourlyForecast extends StatelessWidget {
  final WeatherViewModel vm;

  const HourlyForecast({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final data = vm.weatherData!;

    return SizedBox(
      height: height110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: data.hourly.length,
        itemBuilder: (context, i) {
          final hour = data.hourly[i];
          final wmo = vm.getWmoDetails(hour.weatherCode, 1);

          return Container(
            width: width80,
            margin: EdgeInsets.only(right: pd12h),
            padding: EdgeInsets.symmetric(vertical: pd12v, horizontal: pd8h),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(radius16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 40 : 4),
                  blurRadius: isDark ? 6 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vm.formatHour(hour.time),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: grayColor,
                  ),
                ),
                Icon(
                  wmo['icon'] as IconData,
                  color: wmo['color'] as Color,
                  size: 24,
                ),
                Text(
                  '${hour.temp.toStringAsFixed(0)}°',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'AbhayaLibre',
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}