import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import '../../core/recognition/unistroke.dart';
import '../models/gesture_model.dart';
import '../services/api_service.dart';

class GestureRepository {
  static const String boxName = 'gestures_box';
  final UnistrokeRecognizer _recognizer = UnistrokeRecognizer();
  final ApiService _apiService = ApiService();

  Future<void> init() async {
    Hive.registerAdapter(GestureModelAdapter());
    await Hive.openBox<GestureModel>(boxName);
  }

  Box<GestureModel> get _box => Hive.box<GestureModel>(boxName);

  List<GestureModel> getGestures() {
    return _box.values.toList();
  }

  Future<void> addGesture(GestureModel gesture) async {
    await _box.put(gesture.id, gesture);
    _syncToBackend();
  }

  Future<void> deleteGesture(String id) async {
    await _box.delete(id);
    _syncToBackend();
  }

  /// Recognize a user-drawn gesture against stored templates.
  GestureModel? findMatch(List<Offset> candidatePoints, {double threshold = 0.80}) {
    // 1. Convert Hive Gestures to Templates
    final templates = <UnistrokeTemplate>[];
    
    for (var g in _box.values.where((g) => g.type == 'gesture')) {
      if (g.data is List) {
        templates.add(_recognizer.createTemplate(g.name, g.data as List, g));
      }
    }

    // 2. Recognize
    // Filter candidate points: Remove nulls (lifts) to simulate single stroke for $1
    final cleanPoints = candidatePoints.whereType<Offset>().toList();
    if (cleanPoints.length < 10) return null;

    final result = _recognizer.recognize(cleanPoints, templates);
    
    // 3. Threshold 
    if (result != null && result.score > threshold) {
      return result.data as GestureModel;
    }
    
    return null;
  }
  
  GestureModel? findCodeMatch(String code) {
      try {
          return _box.values.firstWhere(
            (g) => g.type == 'code' && g.data.toString().toUpperCase() == code.toUpperCase()
          );
      } catch (e) {
          return null;
      }
  }

  Future<void> _syncToBackend() async {
    // Convert local gestures to simplified format for simple sync
    // Real-world: Should handle conflicts, IDs, etc.
    try {
      final gestures = _box.values.map((g) => {
        'id': g.id,
        'name': g.name,
        'type': g.type,
        'action_id': g.actionId,
        'action_data': g.actionData
      }).toList();
      
      await _apiService.syncGestures(gestures);
    } catch (_) {
      // Background sync failure is silent
    }
  }

  Future<void> pullGestures() async {
    final remote = await _apiService.fetchGestures();
    if (remote != null) {
      for (var json in remote) {
        try {
          // Map JSON to GestureModel.
          // Assuming API returns keys compatible with model
          // We need to handle 'data' carefully.
          final g = GestureModel(
             id: json['id'] ?? json['uuid'] ?? DateTime.now().toIso8601String(),
             name: json['name'] ?? 'Synced Gesture',
             type: json['type'] ?? 'gesture',
             data: json['stroke_data'] ?? json['data'], // Handle backend naming variations
             actionId: json['action_type'] ?? json['action_id'] ?? 'flashlight', 
             actionData: json['action_value'] ?? json['action_data'],
          );
          await _box.put(g.id, g);
        } catch (e) {
          print("Error syncing gesture: $e");
        }
      }
    }
  }
}
