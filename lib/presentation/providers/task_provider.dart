import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/task_model_hive.dart';
import '../../data/repositories/local_task_repository.dart';
import '../../data/repositories/supabase_task_repository.dart';
import '../../services/calendar_service.dart';
import '../../services/notification_service.dart';

// ─── Tasks Notifier (local Hive) ────────────────────────────

class TasksNotifier extends ChangeNotifier {
  LocalTaskRepository _localRepo;
  SupabaseTaskRepository _supabaseRepo;
  CalendarService _calendar;
  String userId;

  List<TaskModelHive> _tasks = [];

  List<TaskModelHive> get tasks => _tasks;

  List<TaskModelHive> get completedTasks => _tasks.where((t) => t.isCompleted).toList();
  List<TaskModelHive> get pendingTasks => _tasks.where((t) => !t.isCompleted).toList();
  
  List<TaskModelHive> get upcomingTasks {
    final now = DateTime.now();
    return pendingTasks.where((t) => t.scheduledAt.isAfter(now)).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  List<TaskModelHive> get overdueTasks {
    final now = DateTime.now();
    return pendingTasks.where((t) => t.scheduledAt.isBefore(now)).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  TasksNotifier(this._localRepo, this._supabaseRepo, this._calendar, this.userId) {
    _tasks = _localRepo.getTasks();
    _syncFromSupabase();
  }

  void updateDependencies(String newUserId, LocalTaskRepository localRepo, SupabaseTaskRepository supabaseRepo, CalendarService calendar) {
    _localRepo = localRepo;
    _supabaseRepo = supabaseRepo;
    _calendar = calendar;

    if (userId != newUserId) {
      userId = newUserId;
      _tasks = _localRepo.getTasks();
      _syncFromSupabase();
      notifyListeners();
    }
  }

  Future<void> _syncFromSupabase() async {
    if (userId == 'guest') return;
    try {
      final remoteTasks = await _supabaseRepo.getTasks(userId);
      for (var task in remoteTasks) {
        await _localRepo.updateTask(task);
      }
      _tasks = _localRepo.getTasks();
      notifyListeners();
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  void refresh() {
    _tasks = _localRepo.getTasks();
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    String? description,
    required DateTime scheduledAt,
    List<String> categories = const [],
  }) async {
    try {
      final id = const Uuid().v4();
      TaskModelHive localTask = TaskModelHive(
        id: id,
        userId: userId,
        title: title,
        description: description,
        scheduledAt: scheduledAt,
        createdAt: DateTime.now(),
        isCompleted: false,
        isSyncedToCalendar: false,
        categories: categories,
      );

      // Save to Local DB First (Offline Support)
      await _localRepo.addTask(localTask);

      // Save to Supabase
      try {
        await _supabaseRepo.addTask(localTask);
      } catch (e) {
        debugPrint('⚠️ Supabase sync failed: $e');
      }

      // Try calendar sync
      try {
        final eventId = await _calendar.createEvent(localTask);
        localTask = localTask.copyWith(
          isSyncedToCalendar: true,
          calendarEventId: eventId,
        );
        await _localRepo.updateTask(localTask);
        try {
          await _supabaseRepo.updateTask(localTask);
        } catch (_) {}
      } catch (e) {
        debugPrint('⚠️ Calendar sync failed (task still saved): $e');
      }

      await NotificationService.scheduleTaskNotification(localTask);
      refresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleComplete(String taskId) async {
    final task = _localRepo.getTask(taskId);
    if (task == null) return;
    
    // Update locally
    await _localRepo.toggleComplete(taskId);

    final updated = _localRepo.getTask(taskId)!;

    // Supabase
    try {
      await _supabaseRepo.toggleComplete(taskId, updated.isCompleted);
    } catch (e) {
      debugPrint('Supabase toggle failed: $e');
    }

    if (!updated.isCompleted) {
      await NotificationService.scheduleTaskNotification(updated);
    } else {
      await NotificationService.cancelNotification(taskId);
    }
    
    refresh();
  }

  Future<void> deleteTask(TaskModelHive task) async {
    // Delete locally
    await _localRepo.deleteTask(task.id);
    
    // Supabase
    try {
      await _supabaseRepo.deleteTask(task.id);
    } catch (e) {
      debugPrint('Supabase delete failed: $e');
    }
    
    if (task.calendarEventId != null) {
      await _calendar.deleteEvent(task.calendarEventId!);
    }
    await NotificationService.cancelNotification(task.id);
    refresh();
  }

  Future<void> updateTask(TaskModelHive task) async {
    // Update locally
    await _localRepo.updateTask(task);
    
    // Supabase
    try {
      await _supabaseRepo.updateTask(task);
    } catch (e) {
      debugPrint('Supabase update failed: $e');
    }
    
    refresh();
  }
}
