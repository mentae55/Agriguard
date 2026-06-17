import 'package:flutter/material.dart';
import 'package:agriguard_project/core/core.dart';
import 'package:flutter_svg/svg.dart';
import 'robot_control_screen.dart'; // [NEW] Robot controller UI

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface, // theme-aware background
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
                      color: theme.textTheme.displayMedium?.color ?? Colors.black87,
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
                padding: EdgeInsets.all(24),
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
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.wb_cloudy_rounded,
                            color: Colors.yellow.shade600,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '24 °C',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AbhayaLibre',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // [NEW] Robot Control Action Card
                  _buildRobotControlCard(),
                  SizedBox(height: 24),

                  // General Info Panel
                  _buildSettingsPanel(
                    title: 'General Info',
                    children: [
                      _buildSettingRow(
                        'Device Name',
                        'Device#122',
                        hasEdit: true,
                      ),
                      const Divider(height: 1),
                      _buildSettingRow('Serial Number', 'SN: 12345-ABC'),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Analysis Schedule Panel
                  _buildSettingsPanel(
                    title: 'Analysis Schedule',
                    children: [
                      _buildSettingRow('Sampling Interval', 'Every 10 Min'),
                      const Divider(height: 1),
                      _buildSettingRow('Daily Start Time', '6:00 AM'),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Power & Maintenance Panel
                  _buildSettingsPanel(
                    title: 'Power & Maintenance',
                    children: [
                      _buildToggleRow(
                        'Battery Saver Mode',
                        isBatterySaverEnabled,
                        (val) {
                          setState(() => isBatterySaverEnabled = val);
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingRow(
                        'Firmware',
                        'Version 2.1.4 (Up to Date)',
                      ),
                    ],
                  ),

                  SizedBox(height: 120),
                  // Bottom padding for nav bar overlap
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRobotControlCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RobotControlScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20),
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
            // Icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.videogame_asset_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Robot Controller',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                    ),
                  ),
                  SizedBox(height: 4),
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
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withAlpha(178),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2F0E7), // very pale green interior
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(160), // Darkish Olive Green
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'AbhayaLibre',
              ),
            ),
          ),
          // Body items
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, {bool hasEdit = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Colors.black87,
              fontFamily: 'AbhayaLibre',
            ),
          ),
          SizedBox(width: 16),
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
                      color: Colors.grey.shade500,
                      fontFamily: 'AbhayaLibre',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasEdit) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(140),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit,
                      color: Colors.white,
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

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Colors.black87,
              fontFamily: 'AbhayaLibre',
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            // [fixed] was deprecated activeColor
            activeTrackColor: primaryColor,
            inactiveTrackColor: Colors.grey.shade300,
            inactiveThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
