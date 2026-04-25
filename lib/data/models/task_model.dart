// lib/data/models/task_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/task_entity.dart';

class TaskModel extends TaskEntity {
  TaskModel({
    required super.id,
    required super.userId,
    required super.title,
    super.description,
    required super.scheduledAt,
    super.isSyncedToCalendar,
    super.calendarEventId,
    required super.createdAt,
    super.isCompleted,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      isSyncedToCalendar: data['isSyncedToCalendar'] ?? false,
      calendarEventId: data['calendarEventId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'title': title,
        'description': description,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'isSyncedToCalendar': isSyncedToCalendar,
        'calendarEventId': calendarEventId,
        'createdAt': Timestamp.fromDate(createdAt),
        'isCompleted': isCompleted,
      };
}
