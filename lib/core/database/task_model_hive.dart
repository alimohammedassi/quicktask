// lib/core/database/task_model_hive.dart
import 'package:hive/hive.dart';
import '../../domain/entities/task_entity.dart';

part 'task_model_hive.g.dart';

@HiveType(typeId: 1)
class TaskModelHive extends TaskEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String userId;

  @HiveField(2)
  @override
  final String title;

  @HiveField(3)
  @override
  final String? description;

  @HiveField(4)
  @override
  final DateTime scheduledAt;

  @HiveField(5)
  @override
  final bool isSyncedToCalendar;

  @HiveField(6)
  @override
  final String? calendarEventId;

  @HiveField(7)
  @override
  final DateTime createdAt;

  @HiveField(8)
  @override
  final bool isCompleted;

  TaskModelHive({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.scheduledAt,
    this.isSyncedToCalendar = false,
    this.calendarEventId,
    required this.createdAt,
    this.isCompleted = false,
  }) : super(
          id: id,
          userId: userId,
          title: title,
          description: description,
          scheduledAt: scheduledAt,
          isSyncedToCalendar: isSyncedToCalendar,
          calendarEventId: calendarEventId,
          createdAt: createdAt,
          isCompleted: isCompleted,
        );

  @override
  TaskModelHive copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? scheduledAt,
    bool? isSyncedToCalendar,
    String? calendarEventId,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return TaskModelHive(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isSyncedToCalendar: isSyncedToCalendar ?? this.isSyncedToCalendar,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
