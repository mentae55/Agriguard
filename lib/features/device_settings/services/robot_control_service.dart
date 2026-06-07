// =============================================================================
// robot_control_service.dart
// [NEW] Sends movement commands to the ESP32 via Firebase Realtime Database.
// ESP32 polls /Devices/{MAC}/cmd every 500ms and executes the command.
// =============================================================================

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Valid robot movement commands — must match ESP32 firmware expectations
enum RobotCommand { forward, backward, left, right, stop }

extension RobotCommandExt on RobotCommand {
  /// The string value written to Firebase — matches ESP32 executeMotorCommand()
  String get value {
    switch (this) {
      case RobotCommand.forward:  return 'FORWARD';
      case RobotCommand.backward: return 'BACKWARD';
      case RobotCommand.left:     return 'LEFT';
      case RobotCommand.right:    return 'RIGHT';
      case RobotCommand.stop:     return 'STOP';
    }
  }

  /// Human-readable label for displaying in the UI
  String get label {
    switch (this) {
      case RobotCommand.forward:  return 'Moving Forward';
      case RobotCommand.backward: return 'Moving Backward';
      case RobotCommand.left:     return 'Turning Left';
      case RobotCommand.right:    return 'Turning Right';
      case RobotCommand.stop:     return 'Stopped';
    }
  }
}

class RobotControlService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Sends a movement command to the ESP32 via Firebase.
  /// [deviceMac] — device MAC with colons (e.g. "78:1C:3C:B8:8C:8A")
  /// [command]   — the RobotCommand enum value to send
  /// Returns true on success, false on failure.
  Future<bool> sendCommand({
    required String deviceMac,
    required RobotCommand command,
  }) async {
    try {
      final cmdPath = 'Devices/$deviceMac/cmd';
      await _db.child(cmdPath).set(command.value);
      debugPrint('[RobotControl] Sent command: ${command.value} → $cmdPath');
      return true;
    } catch (e) {
      debugPrint('[RobotControl] Error sending command: $e');
      return false;
    }
  }

  /// Convenience method — always stops the robot. Use on screen dispose or
  /// when the user releases a directional button.
  Future<void> stopRobot(String deviceMac) async {
    await sendCommand(deviceMac: deviceMac, command: RobotCommand.stop);
  }
}
