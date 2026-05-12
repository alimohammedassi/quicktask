// lib/data/repositories/supabase_task_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/database/task_model_hive.dart';

class SupabaseTaskRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> addTask(TaskModelHive task) async {
    await _supabase.from('tasks').insert({
      'id': task.id,
      'user_id': task.userId,
      'title': task.title,
      'description': task.description,
      'scheduled_at': task.scheduledAt.toIso8601String(),
      'is_synced_to_calendar': task.isSyncedToCalendar,
      'calendar_event_id': task.calendarEventId,
      'created_at': task.createdAt.toIso8601String(),
      'is_completed': task.isCompleted,
      'categories': task.categories,
    });
  }

  Future<void> updateTask(TaskModelHive task) async {
    await _supabase.from('tasks').update({
      'title': task.title,
      'description': task.description,
      'scheduled_at': task.scheduledAt.toIso8601String(),
      'is_synced_to_calendar': task.isSyncedToCalendar,
      'calendar_event_id': task.calendarEventId,
      'is_completed': task.isCompleted,
      'categories': task.categories,
    }).eq('id', task.id);
  }

  Future<void> toggleComplete(String taskId, bool isCompleted) async {
    await _supabase.from('tasks').update({
      'is_completed': isCompleted,
    }).eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }

  Future<List<TaskModelHive>> getTasks(String userId) async {
    final response = await _supabase.from('tasks').select().eq('user_id', userId);
    return response.map((json) => TaskModelHive(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      scheduledAt: DateTime.parse(json['scheduled_at']),
      isSyncedToCalendar: json['is_synced_to_calendar'] ?? false,
      calendarEventId: json['calendar_event_id'],
      createdAt: DateTime.parse(json['created_at']),
      isCompleted: json['is_completed'] ?? false,
      categories: List<String>.from(json['categories'] ?? []),
    )).toList();
  }
}
