// =============================================================================
// robot_control_screen.dart
// Compatible with new ESP32 firmware (L298N motor driver, Firebase cmd path).
// Upgraded with complete ONLINE/OFFLINE control system, safety flags, and proper enum.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:agriguard_project/core/core.dart';
import 'package:agriguard_project/features/connection_to_device/services/device_provider.dart';
import 'package:agriguard_project/features/connection_to_device/view/select_device_screen.dart';
import '../services/robot_control_service.dart';

enum DeviceConnectionState {
  connecting,
  online,
  offline,
  disconnecting,
}

class RobotControlScreen extends StatefulWidget {
  const RobotControlScreen({super.key});

  @override
  State<RobotControlScreen> createState() => _RobotControlScreenState();
}

class _RobotControlScreenState extends State<RobotControlScreen> {
  final RobotControlService _controlService = RobotControlService();

  RobotCommand _currentCommand = RobotCommand.stop;
  bool _isSending = false;
  String? _errorMsg;

  /// True when the user pressed RUN and the robot is in sustained-run mode.
  bool _isRunning = false;

  // Connection State & Safety Protection flags
  DeviceConnectionState _connectionState = DeviceConnectionState.offline;
  bool _manuallyDisconnected = false;
  bool _isNavigatingAway = false;
  StreamSubscription<DatabaseEvent>? _onlineSubscription;
  String? _deviceMac;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeListener();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deviceMac ??= context.read<DeviceProvider>().savedMac;
    
    // Set initial connection state based on current provider status
    final isOnline = context.read<DeviceProvider>().isDeviceOnline;
    if (_connectionState == DeviceConnectionState.offline && isOnline && !_manuallyDisconnected) {
      setState(() {
        _connectionState = DeviceConnectionState.online;
      });
    }
  }

  @override
  void dispose() {
    _onlineSubscription?.cancel();
    // Safety: stop robot when screen is dismissed
    if (_deviceMac != null) {
      _controlService.stopRobot(_deviceMac!);
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Real-time Firebase Database Listener
  // ---------------------------------------------------------------------------
  void _setupRealtimeListener() {
    final mac = _deviceMac;
    if (mac == null) return;

    _onlineSubscription?.cancel();
    _onlineSubscription = FirebaseDatabase.instance
        .ref('Devices/$mac/online')
        .onValue
        .listen((event) {
      if (!mounted) return;
      final val = event.snapshot.value;
      final bool isOnline = val == true;

      debugPrint('[RobotControl] Realtime Listener detected online = $isOnline');

      if (!isOnline && !_manuallyDisconnected && _connectionState == DeviceConnectionState.online) {
        _handleAutomaticDisconnect();
      } else if (isOnline && !_manuallyDisconnected && _connectionState == DeviceConnectionState.offline) {
        setState(() {
          _connectionState = DeviceConnectionState.online;
        });
      }
    }, onError: (error) {
      debugPrint('[RobotControl] Realtime Listener Error: $error');
    });
  }

  // ---------------------------------------------------------------------------
  // Automatic Disconnection Handler (from Real-time Listener)
  // ---------------------------------------------------------------------------
  Future<void> _handleAutomaticDisconnect() async {
    if (_isNavigatingAway) return;
    
    setState(() {
      _connectionState = DeviceConnectionState.disconnecting;
    });

    final mac = _deviceMac;
    if (mac != null) {
      // Stop movement safely
      await _controlService.stopRobot(mac);
      // Wait for safety updates to propagate to Firebase
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;

    _isNavigatingAway = true;
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SelectDeviceScreen()),
      (route) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // Toggle Switch Handler (User manually switching ON/OFF)
  // ---------------------------------------------------------------------------
  Future<void> _toggleOnlineStatus(bool targetOnline) async {
    final mac = _deviceMac;
    if (mac == null) return;

    if (!targetOnline) {
      // User turned OFF the switch
      _manuallyDisconnected = true;
      setState(() {
        _connectionState = DeviceConnectionState.disconnecting;
      });

      // Write online = false, cmd = STOP, status = 0 to Firebase
      await context.read<DeviceProvider>().updateDeviceOnlineStatus(mac, false);

      // Stop current robot movement safely
      await _controlService.stopRobot(mac);

      // Wait 300ms before navigating away for safety commands to be written
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      if (_isNavigatingAway) return;
      _isNavigatingAway = true;

      // Navigate automatically to connection/setup screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SelectDeviceScreen()),
        (route) => false,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Sends the command and updates local state for immediate UI feedback
  // ---------------------------------------------------------------------------
  Future<void> _sendCommand(RobotCommand cmd) async {
    // Block commands if not online
    if (_connectionState != DeviceConnectionState.online) return;

    final mac = _deviceMac;
    if (mac == null) {
      setState(() => _errorMsg = 'No device connected.');
      return;
    }

    setState(() {
      _currentCommand = cmd;
      _isSending = true;
      _errorMsg = null;
    });

    final success = await _controlService.sendCommand(
      deviceMac: mac,
      command: cmd,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        if (!success) _errorMsg = 'Failed to send command. Check connection.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // RUN: sends FORWARD and latches — robot keeps going until STOP is pressed
  // ---------------------------------------------------------------------------
  Future<void> _onRunPressed() async {
    if (_connectionState != DeviceConnectionState.online) return;
    setState(() => _isRunning = true);
    await _sendCommand(RobotCommand.forward);
  }

  // ---------------------------------------------------------------------------
  // STOP: clears run mode and sends STOP
  // ---------------------------------------------------------------------------
  Future<void> _onStopPressed() async {
    if (_connectionState != DeviceConnectionState.online) return;
    setState(() => _isRunning = false);
    await _sendCommand(RobotCommand.stop);
  }

  // ---------------------------------------------------------------------------
  // D-pad: sends directional command on press, STOP on release
  // ---------------------------------------------------------------------------
  Future<void> _onDPadPressed(RobotCommand cmd) async {
    if (_connectionState != DeviceConnectionState.online) return;
    await _sendCommand(cmd);
  }

  Future<void> _onDPadReleased() async {
    if (_connectionState != DeviceConnectionState.online) return;
    if (_isRunning) {
      // In run mode, releasing D-pad returns to FORWARD (sustained)
      await _sendCommand(RobotCommand.forward);
    } else {
      await _sendCommand(RobotCommand.stop);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final bool isOnline = _connectionState == DeviceConnectionState.online;
    final String? mac = _deviceMac;

    final bool showOverlay = _connectionState != DeviceConnectionState.online;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(deviceProvider.isDeviceOnline, mac),
                if (_errorMsg != null) _buildErrorBanner(),
                
                _buildConnectionStateBar(),
                
                _buildStatusPanel(),
                const SizedBox(height: 16),

                // ── RUN / STOP persistent controls ──
                _buildRunStopRow(isOnline),

                const Divider(color: Colors.white12, height: 32),

                // ── Label ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Icon(Icons.gamepad_rounded, color: Colors.white38, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Manual Move',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── D-pad (existing Move UI) ──
                const Spacer(),
                _buildDPad(isOnline),
                const Spacer(),
                const SizedBox(height: 24),
              ],
            ),
            
            // Elegant Offline Overlay / Disabled controls state
            if (showOverlay)
              _buildOfflineOverlay(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header — back button, title, online toggle switch
  // ---------------------------------------------------------------------------
  Widget _buildHeader(bool isOnline, String? mac) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Robot Controller',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'AbhayaLibre',
                    letterSpacing: 0.5,
                  ),
                ),
                if (mac != null)
                  Text(
                    mac,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          _buildOnlineToggleSwitch(isOnline),
        ],
      ),
    );
  }

  Widget _buildOnlineToggleSwitch(bool isOnline) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isOnline
                ? const Color(0xFF1A3A25)
                : const Color(0xFF3A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOnline ? primaryColor : Colors.red.shade800,
              width: 1.0,
            ),
          ),
          child: Text(
            isOnline ? 'ON' : 'OFF',
            style: TextStyle(
              color: isOnline ? primaryColor : Colors.red.shade400,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Switch(
          value: isOnline,
          onChanged: (!isOnline || _connectionState == DeviceConnectionState.disconnecting)
              ? null
              : (val) => _toggleOnlineStatus(val),
          activeTrackColor: primaryColor.withAlpha(128),
          activeThumbColor: Colors.white,
          inactiveThumbColor: Colors.white60,
          inactiveTrackColor: Colors.white12,
        ),
      ],
    );
  }

  Widget _buildConnectionStateBar() {
    Color barColor;
    String statusText;
    IconData icon;
    
    switch (_connectionState) {
      case DeviceConnectionState.online:
        barColor = const Color(0xFF1A3A25);
        statusText = 'AgriGuard Robot is Online & Ready';
        icon = Icons.check_circle_outline_rounded;
        break;
      case DeviceConnectionState.connecting:
        barColor = const Color(0xFF1A2F3A);
        statusText = 'Establishing connection to Robot...';
        icon = Icons.wifi_protected_setup_rounded;
        break;
      case DeviceConnectionState.disconnecting:
        barColor = const Color(0xFF3A291A);
        statusText = 'Disconnecting and stopping robot...';
        icon = Icons.stop_screen_share_rounded;
        break;
      case DeviceConnectionState.offline:
        barColor = const Color(0xFF3A1A1A);
        statusText = 'Robot is Offline. Waiting for robot to connect...';
        icon = Icons.wifi_off_rounded;
        break;
    }
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: barColor.withAlpha(128),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: barColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineOverlay() {
    String message = 'Controls Disabled';
    Widget actionWidget = const SizedBox.shrink();
    
    if (_connectionState == DeviceConnectionState.offline) {
      message = 'Robot is Offline';
      actionWidget = const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Waiting for AgriGuard Robot to become Online...\nPlease power on/turn on the physical robot to connect.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white38,
            ),
          ),
        ],
      );
    } else if (_connectionState == DeviceConnectionState.connecting) {
      message = 'Connecting...';
      actionWidget = const CircularProgressIndicator(color: Colors.white);
    } else if (_connectionState == DeviceConnectionState.disconnecting) {
      message = 'Disconnecting...';
      actionWidget = const CircularProgressIndicator(color: Colors.red);
    }

    return Positioned(
      top: 130, 
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: const Color(0xFF0D1117).withAlpha(217),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _connectionState == DeviceConnectionState.disconnecting
                    ? Icons.offline_share_rounded
                    : Icons.lock_outline_rounded,
                color: Colors.white30,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              actionWidget,
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Status panel
  // ---------------------------------------------------------------------------
  Widget _buildStatusPanel() {
    final bool isMoving = _currentCommand != RobotCommand.stop;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMoving
              ? [primaryColor.withAlpha(40), primaryColor.withAlpha(15)]
              : [Colors.white10, Colors.white.withAlpha(5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMoving ? primaryColor.withAlpha(120) : Colors.white12,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _commandIcon(_currentCommand),
              key: ValueKey(_currentCommand),
              color: isMoving ? primaryColor : Colors.white38,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isRunning ? 'AUTO RUN' : 'Manual',
                  style: TextStyle(
                    color: _isRunning ? primaryColor.withAlpha(180) : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _currentCommand.label,
                    key: ValueKey(_currentCommand.label),
                    style: TextStyle(
                      color: isMoving ? Colors.white : Colors.white60,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'AbhayaLibre',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isSending)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  IconData _commandIcon(RobotCommand cmd) {
    switch (cmd) {
      case RobotCommand.forward:  return Icons.arrow_upward_rounded;
      case RobotCommand.backward: return Icons.arrow_downward_rounded;
      case RobotCommand.left:     return Icons.arrow_back_rounded;
      case RobotCommand.right:    return Icons.arrow_forward_rounded;
      case RobotCommand.stop:     return Icons.stop_circle_outlined;
    }
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_errorMsg ?? '',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RUN / STOP row — sustained mode controls
  // ---------------------------------------------------------------------------
  Widget _buildRunStopRow(bool isOnline) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // ── RUN button ──
          Expanded(
            child: GestureDetector(
              onTap: (isOnline && !_isRunning) ? _onRunPressed : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 60,
                decoration: BoxDecoration(
                  gradient: _isRunning
                      ? LinearGradient(
                          colors: [primaryColor, primaryColor.withAlpha(180)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            isOnline ? primaryColor.withAlpha(60) : Colors.white10,
                            isOnline ? primaryColor.withAlpha(30) : Colors.white10,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isRunning
                        ? primaryColor
                        : (isOnline ? primaryColor.withAlpha(120) : Colors.white12),
                    width: 1.5,
                  ),
                  boxShadow: _isRunning
                      ? [
                          BoxShadow(
                            color: primaryColor.withAlpha(100),
                            blurRadius: 18,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: isOnline ? Colors.white : Colors.white24,
                      size: 28,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'RUN',
                      style: TextStyle(
                        color: isOnline ? Colors.white : Colors.white24,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // ── STOP button ──
          Expanded(
            child: GestureDetector(
              onTap: isOnline ? _onStopPressed : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 60,
                decoration: BoxDecoration(
                  color: (!_isRunning && _currentCommand == RobotCommand.stop)
                      ? const Color(0xFFB71C1C).withAlpha(220)
                      : const Color(0xFFB71C1C).withAlpha(80),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: (!_isRunning && _currentCommand == RobotCommand.stop)
                        ? const Color(0xFFEF5350)
                        : const Color(0xFFEF5350).withAlpha(80),
                    width: 1.5,
                  ),
                  boxShadow: (!_isRunning && _currentCommand == RobotCommand.stop)
                      ? [
                          BoxShadow(
                            color: Colors.red.withAlpha(100),
                            blurRadius: 18,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stop_circle_rounded,
                      color: isOnline ? Colors.white : Colors.white24,
                      size: 26,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'STOP',
                      style: TextStyle(
                        color: isOnline ? Colors.white : Colors.white24,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // D-Pad — existing Move UI (unchanged layout)
  // ---------------------------------------------------------------------------
  Widget _buildDPad(bool isOnline) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Forward
        _buildDPadButton(
          command: RobotCommand.forward,
          icon: Icons.keyboard_arrow_up_rounded,
          label: 'Forward',
          isEnabled: isOnline,
        ),
        const SizedBox(height: 8),
        // Left | Center | Right
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDPadButton(
              command: RobotCommand.left,
              icon: Icons.keyboard_arrow_left_rounded,
              label: 'Left',
              isEnabled: isOnline,
            ),
            // Center robot icon
            Container(
              width: 72,
              height: 72,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _isRunning
                    ? primaryColor.withAlpha(30)
                    : Colors.white.withAlpha(8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRunning ? primaryColor.withAlpha(80) : Colors.white12,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                color: _isRunning ? primaryColor.withAlpha(160) : Colors.white24,
                size: 32,
              ),
            ),
            _buildDPadButton(
              command: RobotCommand.right,
              icon: Icons.keyboard_arrow_right_rounded,
              label: 'Right',
              isEnabled: isOnline,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Backward
        _buildDPadButton(
          command: RobotCommand.backward,
          icon: Icons.keyboard_arrow_down_rounded,
          label: 'Back',
          isEnabled: isOnline,
        ),
      ],
    );
  }

  /// Directional button: press → sends command, release → sends STOP (or FORWARD in run mode)
  Widget _buildDPadButton({
    required RobotCommand command,
    required IconData icon,
    required String label,
    required bool isEnabled,
  }) {
    final bool isActive = _currentCommand == command;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => _onDPadPressed(command) : null,
      onTapUp: isEnabled ? (_) => _onDPadReleased() : null,
      onTapCancel: isEnabled ? _onDPadReleased : null,
      onLongPressStart: isEnabled ? (_) => _onDPadPressed(command) : null,
      onLongPressEnd: isEnabled ? (_) => _onDPadReleased() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive ? primaryColor : Colors.white24,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: primaryColor.withAlpha(80),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isEnabled
                  ? (isActive ? Colors.white : Colors.white70)
                  : Colors.white24,
              size: 38,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isEnabled
                    ? (isActive ? Colors.white : Colors.white38)
                    : Colors.white12,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
