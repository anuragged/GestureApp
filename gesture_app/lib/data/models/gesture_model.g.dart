part of 'gesture_model.dart';

class GestureModelAdapter extends TypeAdapter<GestureModel> {
  @override
  final int typeId = 0;

  @override
  GestureModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GestureModel(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      data: fields[3] as dynamic,
      actionId: fields[4] as String,
      actionData: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GestureModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.actionId)
      ..writeByte(5)
      ..write(obj.actionData);
  }
}
