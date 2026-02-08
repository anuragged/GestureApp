import 'package:flutter/services.dart';
import 'dart:async';

class PermissionHelper {
  static const MethodChannel _channel = MethodChannel('com.example.gesture_app/permissions');

  static final StreamController<String> _actionStreamController = StreamController<String>.broadcast();
  static Stream<String> get actionStream => _actionStreamController.stream;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onActionReceived') {
        final action = call.arguments as String;
        _actionStreamController.add(action);
      }
    });
  }

  static Future<Map<String, bool>> checkPermissions() async {
    final Map<dynamic, dynamic> result = await _channel.invokeMethod('checkPermissions');
    return Map<String, bool>.from(result);
  }

  static Future<void> requestOverlay() async {
    await _channel.invokeMethod('requestOverlay');
  }

  static Future<void> requestBatteryOptimization() async {
    await _channel.invokeMethod('requestBatteryOptimization');
  }

  static Future<void> openNotificationSettings() async {
    await _channel.invokeMethod('openNotificationSettings');
  }

  static Future<void> startService() async {
    await _channel.invokeMethod('startService');
  }
  
  static Future<String?> getInitialAction() async {
    return await _channel.invokeMethod('getInitialAction');
  }
}
