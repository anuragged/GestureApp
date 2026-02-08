
import 'package:flutter/services.dart';

class BubbleCustomizer {
  static const MethodChannel _channel = MethodChannel('com.example.gesture_app/permissions');

  static Future<void> updateBubbleOpacity(double opacity) async {
    try {
      await _channel.invokeMethod('updateBubbleOpacity', {'opacity': opacity});
    } catch (_) {}
  }
  
  static Future<void> updateBubbleSize(String size) async {
    try {
      await _channel.invokeMethod('updateBubbleSize', {'size': size}); // 'small', 'medium', 'large'
    } catch (_) {}
  }
  
  static Future<void> updateBubbleColor(String colorObj) async {
    try {
      // Pass color as HEX String e.g. "#FF0000"
      await _channel.invokeMethod('updateBubbleColor', {'color': colorObj});
    } catch (_) {}
  }

  static Future<void> updateBubbleIcon(String iconType) async {
      try {
        await _channel.invokeMethod('updateBubbleIcon', {'icon': iconType}); // 'pen', 'bolt', 'dot'
      } catch (_) {}
  }
  
  static Future<void> updateBubbleLock(bool locked) async {
      try {
         await _channel.invokeMethod('updateBubbleLock', {'locked': locked});
      } catch (_) {}
  }

  static Future<void> updateShakeToWake(bool enabled) async {
       try {
           // We might need to handle shake logic in Dart (using shake package) OR Native.
           // Since background service is native, native is better if app is killed, 
           // BUT shake detection usually requires visible activity or foreground service.
           // Our Foreground Service typically handles only the bubble view.
           // However, let's send to native so native service can register sensors.
          await _channel.invokeMethod('updateShakeToWake', {'enabled': enabled});
       } catch (_) {}
  }
}
