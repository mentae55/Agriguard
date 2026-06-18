// lib/presentation/widgets/weather/city_selector.dart
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../data/model/weather_model.dart';
import '../../view_model/weather_viewmodel.dart';

class CitySelector extends StatelessWidget {
  final WeatherViewModel vm;

  const CitySelector({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 5),
            blurRadius: isDark ? 8 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CityConfig>(
          value: vm.selectedCity,
          icon: Icon(Icons.arrow_drop_down_rounded, color: primaryColor, size: 30),
          isExpanded: true,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontFamily: 'AbhayaLibre',
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
          borderRadius: BorderRadius.circular(radius16),
          items: vm.cities.map((city) {
            return DropdownMenuItem<CityConfig>(
              value: city,
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(city.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) vm.selectCity(val);
          },
        ),
      ),
    );
  }
}