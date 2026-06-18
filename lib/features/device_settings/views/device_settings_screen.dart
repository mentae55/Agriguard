import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_project/core/core.dart';
import 'package:flutter_svg/svg.dart';
import '../viewmodels/device_settings_view_model.dart';
import 'robot_control_screen.dart';

class DeviceSettingsScreen extends StatefulWidget {
  final String serial;

  const DeviceSettingsScreen({super.key, required this.serial});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceSettingsViewModel>().loadSettings();
    });
  }


  void _showFeedbackSnackBarDirect(ScaffoldMessengerState messenger, bool success, String successMessage) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? successMessage : 'Failed to save settings. Please try again.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editDeviceName(BuildContext context, DeviceSettingsViewModel vm, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Text(
            'Edit Device Name',
            style: TextStyle(fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w900),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                hintText: 'e.g. Farm Robot Alpha',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Device name cannot be empty';
                }
                if (val.length > 25) {
                  return 'Name must be 25 characters or less';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await vm.updateDeviceName(controller.text.trim());
                  if (mounted) {
                    _showFeedbackSnackBarDirect(messenger, success, 'Device name updated successfully');
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSamplingIntervalDialog(BuildContext context, DeviceSettingsViewModel vm, String currentValue) {
    final options = [
      'Every 5 Minutes',
      'Every 10 Minutes',
      'Every 15 Minutes',
      'Every 30 Minutes',
      'Every 1 Hour',
      'Every 3 Hours',
      'Every 6 Hours',
      'Every 12 Hours',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text(
            'Select Sampling Interval',
            style: TextStyle(fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w900),
          ),
          children: options.map((opt) {
            final isSelected = opt == currentValue;
            return SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final success = await vm.updateSamplingInterval(opt);
                if (mounted) {
                  _showFeedbackSnackBarDirect(messenger, success, 'Sampling interval updated successfully');
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      opt,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check, color: Theme.of(context).primaryColor),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showStartTimePicker(BuildContext context, DeviceSettingsViewModel vm, String currentValue) async {
    TimeOfDay initialTime = const TimeOfDay(hour: 6, minute: 0);
    try {
      final parts = currentValue.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPm = parts[1].toUpperCase() == 'PM';
      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      initialTime = TimeOfDay(hour: hour, minute: minute);
    } catch (_) {}

    final messenger = ScaffoldMessenger.of(context);
    final localizations = MaterialLocalizations.of(context);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null && mounted) {
      final formattedTime = localizations.formatTimeOfDay(pickedTime, alwaysUse24HourFormat: false);
      final success = await vm.updateDailyStartTime(formattedTime);
      if (mounted) {
        _showFeedbackSnackBarDirect(messenger, success, 'Daily start time updated successfully');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Consumer<DeviceSettingsViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.state == DeviceSettingsState.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: ${vm.errorMessage}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => vm.loadSettings(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final settings = vm.settings!;

            return Stack(
              children: [
                Column(
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
                          SvgPicture.asset(
                            'assets/app_images/icons/logo.svg',
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
                              Expanded(
                                child: Text(
                                  settings.deviceName,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'AbhayaLibre',
                                    letterSpacing: 0.5,
                                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                                value: settings.deviceName,
                                hasEdit: true,
                                onTap: vm.isSaving
                                    ? null
                                    : () => _editDeviceName(context, vm, settings.deviceName),
                              ),
                              Divider(height: 1, color: theme.dividerColor),
                              _buildSettingRow(
                                theme: theme,
                                label: 'Serial Number',
                                value: settings.serialNumber,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Analysis Schedule Panel
                          _buildSettingsPanel(
                            theme: theme,
                            isDark: isDark,
                            title: 'Analysis Schedule',
                            children: [
                              _buildSettingRow(
                                theme: theme,
                                label: 'Sampling Interval',
                                value: settings.samplingInterval,
                                onTap: vm.isSaving
                                    ? null
                                    : () => _showSamplingIntervalDialog(context, vm, settings.samplingInterval),
                              ),
                              Divider(height: 1, color: theme.dividerColor),
                              _buildSettingRow(
                                theme: theme,
                                label: 'Daily Start Time',
                                value: settings.dailyStartTime,
                                onTap: vm.isSaving
                                    ? null
                                    : () => _showStartTimePicker(context, vm, settings.dailyStartTime),
                              ),
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
                                value: settings.batterySaverEnabled,
                                onChanged: vm.isSaving
                                    ? null
                                    : (val) async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        final success = await vm.updateBatterySaver(val);
                                        if (mounted) {
                                          _showFeedbackSnackBarDirect(
                                            messenger,
                                            success,
                                            val
                                                ? 'Battery saver mode enabled'
                                                : 'Battery saver mode disabled',
                                          );
                                        }
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
                if (vm.isSaving)
                  Container(
                    color: Colors.black.withAlpha(50),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
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
                      decoration: const BoxDecoration(
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
      ),
    );
  }

  Widget _buildToggleRow({
    required ThemeData theme,
    required bool isDark,
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
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
