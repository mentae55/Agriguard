import 'package:flutter/material.dart';
import '../../features/connection_to_device/view/select_device_screen.dart';
import '../constants/app_colors.dart';

class NoWifiScreen extends StatelessWidget {
  const NoWifiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.wifi_off_rounded, size: 100, color: colorScheme.onPrimary),
              const SizedBox(height: 32),
              Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onPrimary,
                  fontFamily: 'AbhayaLibre',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please turn on your Wi-Fi or mobile data to continue using AgriGuard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onPrimary.withAlpha(178),
                ),
              ),
              const SizedBox(height: 16),
              CircularProgressIndicator(color: colorScheme.onPrimary), // Visual cue it's waiting
            ],
          ),
        ),
      ),
    );
  }
}

class DeviceOfflineScreen extends StatelessWidget {
  final VoidCallback onDismissed;
  
  const DeviceOfflineScreen({super.key, required this.onDismissed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.device_unknown_rounded, size: 100, color: redColor),
              const SizedBox(height: 32),
              Text(
                'Device Disconnected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                  fontFamily: 'AbhayaLibre',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The ESP32 firmware is offline. Please turn on your device, check its power supply, and ensure it has internet access.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface.withAlpha(180),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  onDismissed();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const SelectDeviceScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Go to Connect Page', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
