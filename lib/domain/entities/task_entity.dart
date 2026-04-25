// lib/domain/entities/task_entity.dart

class TaskEntity {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final bool isSyncedToCalendar;
  final String? calendarEventId;
  final DateTime createdAt;
  final bool isCompleted;

  const TaskEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.scheduledAt,
    this.isSyncedToCalendar = false,
    this.calendarEventId,
    required this.createdAt,
    this.isCompleted = false,
  });

  TaskEntity copyWith({
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
    return TaskEntity(
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
