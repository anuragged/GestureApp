import 'package:hive/hive.dart';

part 'gesture_model.g.dart';

@HiveType(typeId: 0)
class GestureModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type; // 'gesture' or 'code'

  @HiveField(3)
  final dynamic data; // List<Map<String, double>> for gesture, String for code

  @HiveField(4)
  final String actionId; // 'flashlight', 'open_app', etc.

  @HiveField(5)
  final String? actionData; // package name etc.

  GestureModel({
    required this.id,
    required this.name,
    required this.type,
    required this.data,
    required this.actionId,
    this.actionData,
  });
}
