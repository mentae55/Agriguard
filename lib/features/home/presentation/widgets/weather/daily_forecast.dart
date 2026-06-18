// lib/presentation/widgets/weather/daily_forecast.dart
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../view_model/weather_viewmodel.dart';

class DailyForecast extends StatelessWidget {
  final WeatherViewModel vm;

  const DailyForecast({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final data = vm.weatherData!;

    return Container(
      padding: EdgeInsets.symmetric(vertical: pd8v, horizontal: pd16h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(radius20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 5),
            blurRadius: isDark ? 8 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.daily.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
        itemBuilder: (context, i) {
          final day = data.daily[i];
          final wmo = vm.getWmoDetails(day.weatherCode, 1);

          return Padding(
            padding: EdgeInsets.symmetric(vertical: pd12v),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    vm.formatDayName(day.date),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'AbhayaLibre',
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Icon(
                    wmo['icon'] as IconData,
                    color: wmo['color'] as Color,
                    size: 24,
                  ),
                ),
                SizedBox(width: width8),
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${day.tempMin.toStringAsFixed(0)}°',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                      SizedBox(width: width8),
                      Expanded(
                        child: Container(
                          height: height4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                primaryColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: width8),
                      Text(
                        '${day.tempMax.toStringAsFixed(0)}°',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
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