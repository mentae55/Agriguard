import 'package:flutter/material.dart';
import 'package:agriguard_project/core/core.dart';
import 'package:flutter_svg/svg.dart';
import 'robot_control_screen.dart';

class DeviceSettingsScreen extends StatefulWidget {
  final String serial;

  const DeviceSettingsScreen({super.key, required this.serial});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  bool isBatterySaverEnabled = false;

  @override
  Widget build(BuildContext context) {
    String formattedSerial = widget.serial.isEmpty ? '122' : widget.serial;
    if (formattedSerial.length > 6) {
      formattedSerial = formattedSerial.substring(0, 6).toUpperCase();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Device Setting',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SvgPicture.asset('assets/app_images/icons/logo.svg',
                    height: height48,
                    width: width50,
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Device Title & Weather
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Device #$formattedSerial',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'AbhayaLibre',
                          letterSpacing: 0.5,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.wb_cloudy_rounded,
                            color: Colors.yellow.shade600,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '24 °C',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AbhayaLibre',
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildRobotControlCard(theme),
                  const SizedBox(height: 24),

                  // General Info Panel
                  _buildSettingsPanel(
                    theme: theme,
                    isDark: isDark,
                    title: 'General Info',
                    children: [
                      _buildSettingRow(
                        theme: theme,
                        label: 'Device Name',
                        value: 'Device#122',
                        hasEdit: true,
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      _buildSettingRow(theme: theme, label: 'Serial Number', value: 'SN: 12345-ABC'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Analysis Schedule Panel
                  _buildSettingsPanel(
                    theme: theme,
                    isDark: isDark,
                    title: 'Analysis Schedule',
                    children: [
                      _buildSettingRow(theme: theme, label: 'Sampling Interval', value: 'Every 10 Min'),
                      Divider(height: 1, color: theme.dividerColor),
                      _buildSettingRow(theme: theme, label: 'Daily Start Time', value: '6:00 AM'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Power & Maintenance Panel
                  _buildSettingsPanel(
                    theme: theme,
                    isDark: isDark,
                    title: 'Power & Maintenance',
                    children: [
                      _buildToggleRow(
                        theme: theme,
                        isDark: isDark,
                        label: 'Battery Saver Mode',
                        value: isBatterySaverEnabled,
                        onChanged: (val) {
                          setState(() => isBatterySaverEnabled = val);
                        },
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      _buildSettingRow(
                        theme: theme,
                        label: 'Firmware',
                        value: 'Version 2.1.4 (Up to Date)',
                      ),
                    ],
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRobotControlCard(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RobotControlScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withAlpha(180)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.videogame_asset_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Robot Controller',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Control movement in real time',
                    style: TextStyle(
                      color: Colors.white.withAlpha(178),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : const Color(0xFFE2F0E7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withAlpha(isDark ? 10 : 5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.tertiary : primaryColor.withAlpha(160),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'AbhayaLibre',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required ThemeData theme,
    required String label,
    required String value,
    bool hasEdit = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
              fontFamily: 'AbhayaLibre',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                      fontFamily: 'AbhayaLibre',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasEdit) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit,
                      color: theme.colorScheme.onPrimary,
                      size: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required ThemeData theme,
    required bool isDark,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
              fontFamily: 'AbhayaLibre',
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: primaryColor,
            inactiveTrackColor: isDark ? Colors.white24 : Colors.grey.shade300,
            inactiveThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
