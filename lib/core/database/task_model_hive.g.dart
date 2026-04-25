// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelHiveAdapter extends TypeAdapter<TaskModelHive> {
  @override
  final int typeId = 1;

  @override
  TaskModelHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModelHive(
      id: fields[0] as String,
      userId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String?,
      scheduledAt: fields[4] as DateTime,
      isSyncedToCalendar: fields[5] as bool,
      calendarEventId: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      isCompleted: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModelHive obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.scheduledAt)
      ..writeByte(5)
      ..write(obj.isSyncedToCalendar)
      ..writeByte(6)
      ..write(obj.calendarEventId)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
