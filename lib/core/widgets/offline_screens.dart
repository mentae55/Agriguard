import 'package:flutter/material.dart';
import '../../features/connection_to_device/view/select_device_screen.dart';
import '../constants/app_colors.dart';

class NoWifiScreen extends StatelessWidget {
  const NoWifiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 100, color: Colors.white),
              const SizedBox(height: 32),
              const Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'AbhayaLibre',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please turn on your Wi-Fi or mobile data to continue using AgriGuard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: Colors.white), // Visual cue it's waiting
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
    return Scaffold(
      backgroundColor: secondaryColor, // Soft cream background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.device_unknown_rounded, size: 100, color: Colors.red.shade400),
              const SizedBox(height: 32),
              const Text(
                'Device Disconnected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  fontFamily: 'AbhayaLibre',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The ESP32 firmware is offline. Please turn on your device, check its power supply, and ensure it has internet access.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
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
