import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:agriguard_project/core/core.dart';

// ═════════════════════════════════════════════
//  DATA MODELS & CONFIG
// ═════════════════════════════════════════════

class CityConfig {
  final String name;
  final double lat;
  final double lon;
  final String timezone;

  const CityConfig({
    required this.name,
    required this.lat,
    required this.lon,
    required this.timezone,
  });
}

const List<CityConfig> _cities = [
  CityConfig(name: 'Cairo', lat: 30.0444, lon: 31.2357, timezone: 'Africa/Cairo'),
  CityConfig(name: 'Alexandria', lat: 31.2001, lon: 29.9187, timezone: 'Africa/Cairo'),
  CityConfig(name: 'Luxor', lat: 25.6872, lon: 32.6396, timezone: 'Africa/Cairo'),
  CityConfig(name: 'Aswan', lat: 24.0889, lon: 32.8998, timezone: 'Africa/Cairo'),
  CityConfig(name: 'Seongnam-si', lat: 37.4200, lon: 127.1265, timezone: 'Asia/Seoul'),
];

class WeatherData {
  final double temp;
  final int humidity;
  final double feelsLike;
  final double windSpeed;
  final double windDir;
  final double precipitation;
  final int weatherCode;
  final int isDay;
  final double uvIndex;
  final String sunrise;
  final String sunset;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  WeatherData({
    required this.temp,
    required this.humidity,
    required this.feelsLike,
    required this.windSpeed,
    required this.windDir,
    required this.precipitation,
    required this.weatherCode,
    required this.isDay,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
    required this.hourly,
    required this.daily,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final hourlyMap = json['hourly'] as Map<String, dynamic>;
    final dailyMap = json['daily'] as Map<String, dynamic>;

    // Parse hourly (next 24 hours)
    final List<HourlyForecast> hourlyList = [];
    final times = hourlyMap['time'] as List;
    final temps = hourlyMap['temperature_2m'] as List;
    final codes = hourlyMap['weather_code'] as List;
    
    // Find current hour index or start from index 0
    final String nowStr = current['time'] as String;
    int startIndex = 0;
    try {
      final nowTime = DateTime.parse(nowStr);
      for (int i = 0; i < times.length; i++) {
        final t = DateTime.parse(times[i] as String);
        if (t.isAfter(nowTime) || t.isAtSameMomentAs(nowTime)) {
          startIndex = i;
          break;
        }
      }
    } catch (_) {}

    // Take next 24 hours from current
    for (int i = startIndex; i < math.min(startIndex + 24, times.length); i++) {
      hourlyList.add(HourlyForecast(
        time: times[i] as String,
        temp: (temps[i] as num).toDouble(),
        weatherCode: (codes[i] as num).toInt(),
      ));
    }

    // Parse daily (7 days)
    final List<DailyForecast> dailyList = [];
    final dTimes = dailyMap['time'] as List;
    final dMaxes = dailyMap['temperature_2m_max'] as List;
    final dMins = dailyMap['temperature_2m_min'] as List;
    final dCodes = dailyMap['weather_code'] as List;

    for (int i = 0; i < math.min(7, dTimes.length); i++) {
      dailyList.add(DailyForecast(
        date: dTimes[i] as String,
        tempMax: (dMaxes[i] as num).toDouble(),
        tempMin: (dMins[i] as num).toDouble(),
        weatherCode: (dCodes[i] as num).toInt(),
      ));
    }

    // Sunrise & Sunset format
    String sunriseStr = '';
    String sunsetStr = '';
    try {
      final sunrises = dailyMap['sunrise'] as List;
      final sunsets = dailyMap['sunset'] as List;
      if (sunrises.isNotEmpty && sunsets.isNotEmpty) {
        sunriseStr = sunrises[0] as String;
        sunsetStr = sunsets[0] as String;
      }
    } catch (_) {}

    // UV Index
    double uvVal = 0.0;
    try {
      final uvs = dailyMap['uv_index_max'] as List;
      if (uvs.isNotEmpty) {
        uvVal = (uvs[0] as num).toDouble();
      }
    } catch (_) {}

    return WeatherData(
      temp: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      windDir: (current['wind_direction_10m'] as num).toDouble(),
      precipitation: (current['precipitation'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      isDay: (current['is_day'] as num).toInt(),
      uvIndex: uvVal,
      sunrise: sunriseStr,
      sunset: sunsetStr,
      hourly: hourlyList,
      daily: dailyList,
    );
  }
}

class HourlyForecast {
  final String time;
  final double temp;
  final int weatherCode;

  HourlyForecast({required this.time, required this.temp, required this.weatherCode});
}

class DailyForecast {
  final String date;
  final double tempMax;
  final double tempMin;
  final int weatherCode;

  DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.weatherCode,
  });
}

// ═════════════════════════════════════════════
//  SCREEN STATE
// ═════════════════════════════════════════════

class WeatherDetailsScreen extends StatefulWidget {
  const WeatherDetailsScreen({super.key});

  @override
  State<WeatherDetailsScreen> createState() => _WeatherDetailsScreenState();
}

class _WeatherDetailsScreenState extends State<WeatherDetailsScreen>
    with SingleTickerProviderStateMixin {
  CityConfig _selectedCity = _cities[0]; // Default to Cairo
  WeatherData? _weatherData;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fetchWeather();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast'
          '?latitude=${_selectedCity.lat}'
          '&longitude=${_selectedCity.lon}'
          '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,wind_direction_10m'
          '&hourly=temperature_2m,weather_code'
          '&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max'
          '&timezone=auto');

      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final data = WeatherData.fromJson(decoded);

        if (mounted) {
          setState(() {
            _weatherData = data;
            _isLoading = false;
          });
          _animationController.forward(from: 0.0);
        }
      } else {
        throw Exception('API error (${res.statusCode})');
      }
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

  // Helper mappings for WMO weather codes
  Map<String, dynamic> _getWmoDetails(int code, int isDay) {
    switch (code) {
      case 0:
        return {
          'desc': 'Clear Sky',
          'icon': isDay == 1 ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
          'color': isDay == 1 ? Colors.orange.shade400 : Colors.indigo.shade300,
        };
      case 1:
      case 2:
      case 3:
        return {
          'desc': code == 1 ? 'Mainly Clear' : code == 2 ? 'Partly Cloudy' : 'Overcast',
          'icon': isDay == 1 ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded,
          'color': Colors.blueGrey.shade300,
        };
      case 45:
      case 48:
        return {
          'desc': 'Foggy',
          'icon': Icons.filter_drama_rounded,
          'color': Colors.grey.shade400,
        };
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return {
          'desc': 'Drizzle',
          'icon': Icons.grain_rounded,
          'color': Colors.blue.shade300,
        };
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return {
          'desc': 'Rainy',
          'icon': Icons.umbrella_rounded,
          'color': Colors.blue.shade600,
        };
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return {
          'desc': 'Snowy',
          'icon': Icons.ac_unit_rounded,
          'color': Colors.lightBlue.shade200,
        };
      case 80:
      case 81:
      case 82:
        return {
          'desc': 'Rain Showers',
          'icon': Icons.water_drop_rounded,
          'color': Colors.blue.shade700,
        };
      case 95:
      case 96:
      case 97:
        return {
          'desc': 'Thunderstorm',
          'icon': Icons.thunderstorm_rounded,
          'color': Colors.deepPurple.shade400,
        };
      default:
        return {
          'desc': 'Unknown',
          'icon': Icons.wb_cloudy_rounded,
          'color': Colors.grey.shade400,
        };
    }
  }

  // Date parsing to display Mon, Tue, etc.
  String _formatDayName(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final today = DateTime.now();
      if (date.year == today.year && date.month == today.month && date.day == today.day) {
        return 'Today';
      }
      const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdayNames[date.weekday - 1];
    } catch (_) {
      return dateStr;
    }
  }

  // Time parsing to display e.g. "11 PM"
  String _formatHour(String timeStr) {
    try {
      final dateTime = DateTime.parse(timeStr);
      final hour = dateTime.hour;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
      return '$formattedHour $ampm';
    } catch (_) {
      return timeStr;
    }
  }

  // Clean time string from ISO string (e.g. "2026-06-09T04:53" -> "4:53 AM")
  String _formatTimeOnly(String isoStr) {
    if (isoStr.isEmpty) return '--';
    try {
      final dt = DateTime.parse(isoStr);
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = h >= 12 ? 'PM' : 'AM';
      final displayHour = h % 12 == 0 ? 12 : h % 12;
      return '$displayHour:$m $ampm';
    } catch (_) {
      return isoStr;
    }
  }

  // Magnust-Tetens formula for dew point calculation
  double _calculateDewPoint(double temp, int humidity) {
    const double b = 17.625;
    const double c = 243.04;
    final double gamma = (b * temp) / (c + temp) + math.log(humidity / 100);
    return (c * gamma) / (b - gamma);
  }

  // UV level helper
  Map<String, dynamic> _getUvDetails(double index) {
    if (index <= 2) {
      return {'desc': 'Low', 'color': Colors.green};
    } else if (index <= 5) {
      return {'desc': 'Moderate', 'color': Colors.yellow.shade700};
    } else if (index <= 7) {
      return {'desc': 'High', 'color': Colors.orange};
    } else if (index <= 10) {
      return {'desc': 'Very High', 'color': Colors.red};
    } else {
      return {'desc': 'Extreme', 'color': Colors.purple};
    }
  }

  // ── Rendering widgets ──────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.secondary,
      appBar: AppBar(
        backgroundColor: colorScheme.secondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_return_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Weather Details',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            fontSize: 24,
          ),
        ),
        actions: [
          // Live pulse / refresh action
          if (!_isLoading)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: primaryColor),
              onPressed: _fetchWeather,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.wb_cloudy_rounded, color: primaryColor, size: 28),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background plant decoration at bottom right
          Align(
            alignment: Alignment.bottomRight,
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/app_images/images/plant.png',
                height: 160,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            ),
          ),

          if (_isLoading)
            _buildLoading()
          else if (_hasError)
            _buildError()
          else
            _buildContent(),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
          SizedBox(height: 20),
          Text(
            'Retrieving real-time weather...',
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
                  const Icon(Icons.cloud_off_rounded, color: redColor, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Weather fetch failed',
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
              onTap: _fetchWeather,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
                    Icon(Icons.refresh_rounded, color: colorScheme.onPrimary, size: 20),
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

  Widget _buildContent() {
    final data = _weatherData!;
    final wmo = _getWmoDetails(data.weatherCode, data.isDay);

    return FadeTransition(
      opacity: _animationController,
      child: RefreshIndicator(
        onRefresh: _fetchWeather,
        color: primaryColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // City Selector Dropdown / Row
              _buildCitySelector(),
              const SizedBox(height: 20),

              // Current Weather Card
              _buildCurrentWeatherCard(data, wmo),
              const SizedBox(height: 24),

              // Hourly Forecast section
              _buildSectionHeader('Hourly Forecast', Icons.hourglass_top_rounded),
              const SizedBox(height: 12),
              _buildHourlyForecast(data),
              const SizedBox(height: 24),

              // 7-Day Forecast section
              _buildSectionHeader('7-Day Forecast', Icons.calendar_month_rounded),
              const SizedBox(height: 12),
              _buildDailyForecast(data),
              const SizedBox(height: 24),

              // Detailed metrics section
              _buildSectionHeader('Weather Metrics', Icons.grid_view_rounded),
              const SizedBox(height: 12),
              _buildMetricsGrid(data),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildCitySelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
          value: _selectedCity,
          icon: Icon(Icons.arrow_drop_down_rounded, color: primaryColor, size: 30),
          isExpanded: true,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontFamily: 'AbhayaLibre',
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
          borderRadius: BorderRadius.circular(16),
          items: _cities.map((city) {
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
            if (val != null) {
              setState(() {
                _selectedCity = val;
              });
              _fetchWeather();
            }
          },
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard(WeatherData data, Map<String, dynamic> wmo) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Determine gradient depending on whether it is daytime
    final gradientColors = isDark
        ? [const Color(0xFF1A2A20), const Color(0xFF121A16)]
        : (data.isDay == 1
            ? [const Color(0xFFD0E0CC), const Color(0xFFE2F0E7)]
            : [const Color(0xFF2E3E34), const Color(0xFF1E2822)]);
    final textColor = (isDark || data.isDay == 0) ? Colors.white : Colors.black87;
    final subtitleColor = (isDark || data.isDay == 0) ? Colors.white70 : Colors.black54;

    // Daily High/Low for today
    double maxToday = data.temp;
    double minToday = data.temp;
    if (data.daily.isNotEmpty) {
      maxToday = data.daily[0].tempMax;
      minToday = data.daily[0].tempMin;
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(isDark ? 35 : 20),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCity.name,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'AbhayaLibre',
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${wmo['desc']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'AbhayaLibre',
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'H: ${maxToday.toStringAsFixed(0)}°  L: ${minToday.toStringAsFixed(0)}°',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Big Icon
              Icon(
                wmo['icon'] as IconData,
                color: wmo['color'] as Color,
                size: 64,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.temp.toStringAsFixed(0)}°C',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                  color: textColor,
                  height: 1.0,
                ),
              ),
              Text(
                'Feels like ${data.feelsLike.toStringAsFixed(0)}°',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast(WeatherData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: data.hourly.length,
        itemBuilder: (context, i) {
          final hour = data.hourly[i];
          final wmo = _getWmoDetails(hour.weatherCode, 1); // Mock daytime icons for clean look

          return Container(
            width: 76,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
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
                  _formatHour(hour.time),
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

  Widget _buildDailyForecast(WeatherData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.daily.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: theme.dividerColor),
        itemBuilder: (context, i) {
          final day = data.daily[i];
          final wmo = _getWmoDetails(day.weatherCode, 1);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _formatDayName(day.date),
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
                const SizedBox(width: 8),
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
                      const SizedBox(width: 8),
                      // Temperature progress line representation
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [isDark ? Colors.grey.shade700 : Colors.grey.shade300, primaryColor],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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

  Widget _buildMetricsGrid(WeatherData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final uvDetails = _getUvDetails(data.uvIndex);
    final dewPoint = _calculateCurveDewPoint(data.temp, data.humidity);

    // Compute sunrise and sunset times progress
    double dayProgress = 0.0;
    bool isDaytime = false;
    try {
      if (data.sunrise.isNotEmpty && data.sunset.isNotEmpty) {
        final now = DateTime.now();
        final rise = DateTime.parse(data.sunrise);
        final set = DateTime.parse(data.sunset);
        isDaytime = now.isAfter(rise) && now.isBefore(set);
        if (isDaytime) {
          final totalSec = set.difference(rise).inSeconds;
          final currentSec = now.difference(rise).inSeconds;
          dayProgress = (currentSec / totalSec).clamp(0.0, 1.0);
        }
      }
    } catch (_) {}

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        // UV Index card
        _buildGridCard(
          title: 'UV INDEX',
          icon: Icons.wb_sunny_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    data.uvIndex.toStringAsFixed(1),
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    uvDetails['desc'] as String,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: uvDetails['color'] as Color),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (data.uvIndex / 12).clamp(0.0, 1.0),
                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                  color: uvDetails['color'] as Color,
                  minHeight: 6,
                ),
              ),
              Text(
                'Max for today is ${data.uvIndex.toStringAsFixed(1)}.',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withAlpha(160), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // Sunrise & Sunset card
        _buildGridCard(
          title: 'SUNRISE',
          icon: Icons.wb_twilight_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _formatTimeOnly(data.sunrise),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
              ),
              const Spacer(),
              // Sine wave painter
              SizedBox(
                height: 30,
                child: CustomPaint(
                  painter: _SunriseSunsetPainter(dayProgress, isDaytime, isDark: isDark),
                ),
              ),
              const Spacer(),
              Text(
                'Sunset: ${_formatTimeOnly(data.sunset)}',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withAlpha(160), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // Wind speed & compass card
        _buildGridCard(
          title: 'WIND',
          icon: Icons.air_rounded,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.windSpeed.toStringAsFixed(1),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
                    ),
                    Text(
                      'km/h',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurface.withAlpha(160)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Compass widget
              SizedBox(
                width: 64,
                height: 64,
                child: CustomPaint(
                  painter: _CompassPainter(data.windDir, isDark: isDark, surfaceColor: colorScheme.surface),
                ),
              ),
            ],
          ),
        ),

        // Humidity card
        _buildGridCard(
          title: 'HUMIDITY',
          icon: Icons.water_drop_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.humidity}%',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
              ),
              const Spacer(),
              Text(
                'The dew point is\n${dewPoint.toStringAsFixed(1)}°C right now.',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withAlpha(160), fontWeight: FontWeight.w600, height: 1.3),
              ),
            ],
          ),
        ),

        // Feels Like card
        _buildGridCard(
          title: 'FEELS LIKE',
          icon: Icons.thermostat_auto_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.feelsLike.toStringAsFixed(0)}°C',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
              ),
              const Spacer(),
              Text(
                data.feelsLike == data.temp
                    ? 'Similar to actual temp.'
                    : data.feelsLike > data.temp
                        ? 'Feels warmer than actual.'
                        : 'Feels cooler than actual.',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withAlpha(160), fontWeight: FontWeight.w600, height: 1.3),
              ),
            ],
          ),
        ),

        // Rainfall card
        _buildGridCard(
          title: 'RAINFALL',
          icon: Icons.umbrella_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.precipitation.toStringAsFixed(1)} mm',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
              ),
              Text(
                'current volume',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colorScheme.onSurface.withAlpha(160)),
              ),
              const Spacer(),
              Text(
                data.precipitation > 0 ? 'Light to moderate rain is falling.' : 'No rain expected in next 2h.',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withAlpha(160), fontWeight: FontWeight.w600, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 4),
            blurRadius: isDark ? 6 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: grayColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: grayColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  // Renamed internal helper function to avoid shadow conflicts
  double _calculateCurveDewPoint(double t, int h) {
    return _calculateDewPoint(t, h);
  }
}

// ═════════════════════════════════════════════
//  CUSTOM PAINTERS
// ═════════════════════════════════════════════

class _SunriseSunsetPainter extends CustomPainter {
  final double dayProgress;
  final bool isDaytime;
  final bool isDark;

  _SunriseSunsetPainter(this.dayProgress, this.isDaytime, {this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.8;

    // Draw horizon line
    final horizonPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.grey.shade300
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), horizonPaint);

    // Draw dotted curve for sun path
    final pathPaint = Paint()
      ..color = const Color(0xFF66785F).withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(0, horizonY);
    path.quadraticBezierTo(size.width / 2, -size.height * 0.1, size.width, horizonY);
    canvas.drawPath(path, pathPaint);

    // Draw sun dot if daytime
    if (isDaytime) {
      final t = dayProgress.clamp(0.0, 1.0);
      final p0 = Offset(0, horizonY);
      final p1 = Offset(size.width / 2, -size.height * 0.1);
      final p2 = Offset(size.width, horizonY);

      final sunX = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
      final sunY = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;

      final sunPaint = Paint()
        ..color = Colors.yellow.shade700
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(sunX, sunY), 5, sunPaint);
      canvas.drawCircle(Offset(sunX, sunY), 8, Paint()..color = Colors.yellow.shade700.withAlpha(50));
    }
  }

  @override
  bool shouldRepaint(covariant _SunriseSunsetPainter oldDelegate) =>
      oldDelegate.dayProgress != dayProgress || oldDelegate.isDaytime != isDaytime || oldDelegate.isDark != isDark;
}

class _CompassPainter extends CustomPainter {
  final double directionDegrees;
  final bool isDark;
  final Color surfaceColor;

  _CompassPainter(this.directionDegrees, {this.isDark = false, required this.surfaceColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer circle
    final circlePaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, circlePaint);

    // Draw cardinal direction texts N, S, E, W
    final textStyle = TextStyle(
      fontSize: 8,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white38 : Colors.black45,
    );

    void drawText(String text, Offset pos) {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    drawText('N', Offset(center.dx, center.dy - radius + 6));
    drawText('S', Offset(center.dx, center.dy + radius - 6));
    drawText('W', Offset(center.dx - radius + 6, center.dy));
    drawText('E', Offset(center.dx + radius - 6, center.dy));

    // Draw needle
    final needlePaint = Paint()
      ..color = const Color(0xFF66785F)
      ..style = PaintingStyle.fill;

    // Rotate angle (offset by 90 to align North up)
    final angle = (directionDegrees - 90) * math.pi / 180;

    final needlePath = Path();
    final needleLength = radius - 10;
    final needleWidth = 4.0;

    final tip = Offset(center.dx + needleLength * math.cos(angle), center.dy + needleLength * math.sin(angle));
    final leftCorner = Offset(center.dx + needleWidth * math.cos(angle + math.pi / 2), center.dy + needleWidth * math.sin(angle + math.pi / 2));
    final rightCorner = Offset(center.dx + needleWidth * math.cos(angle - math.pi / 2), center.dy + needleWidth * math.sin(angle - math.pi / 2));

    needlePath.moveTo(tip.dx, tip.dy);
    needlePath.lineTo(leftCorner.dx, leftCorner.dy);
    needlePath.lineTo(rightCorner.dx, rightCorner.dy);
    needlePath.close();

    canvas.drawPath(needlePath, needlePaint);

    // Draw pivot
    canvas.drawCircle(center, 3, Paint()..color = surfaceColor);
    canvas.drawCircle(center, 1.5, Paint()..color = const Color(0xFF66785F));
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.directionDegrees != directionDegrees || oldDelegate.isDark != isDark || oldDelegate.surfaceColor != surfaceColor;
}
