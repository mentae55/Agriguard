import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/connection_to_device/view/select_device_screen.dart';
import 'offline_screens.dart';

class GlobalConnectionMonitor extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const GlobalConnectionMonitor({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<GlobalConnectionMonitor> createState() => _GlobalConnectionMonitorState();
}

class _GlobalConnectionMonitorState extends State<GlobalConnectionMonitor> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isWifiOfflineDialogShowing = false;

  @override
  void initState() {
    super.initState();

    // Listen to WiFi/Network drops
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
       final isOffline = results.every((result) => result == ConnectivityResult.none);
       
       if (isOffline && !_isWifiOfflineDialogShowing) {
         _isWifiOfflineDialogShowing = true;
         // Push the No-Wifi screen blocking everything
         widget.navigatorKey.currentState?.push(
           PageRouteBuilder(
             pageBuilder: (context, animation, secondaryAnimation) => const NoWifiScreen(),
             transitionsBuilder: (c, a, s, child) => FadeTransition(opacity: a, child: child),
           )
         );
       } else if (!isOffline && _isWifiOfflineDialogShowing) {
         // WiFi came back!
         _isWifiOfflineDialogShowing = false;
         
         // Force routing to SelectDeviceScreen as requested
         widget.navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SelectDeviceScreen()),
            (route) => false,
         );
       }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
