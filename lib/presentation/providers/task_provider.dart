import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/task_model_hive.dart';
import '../../data/repositories/local_task_repository.dart';
import '../../services/calendar_service.dart';
import '../../services/notification_service.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/models/task_model.dart';

// ─── Tasks Notifier (local Hive + Firebase Sync) ────────────────────────────

class TasksNotifier extends ChangeNotifier {
  LocalTaskRepository _localRepo;
  TaskRepository _remoteRepo;
  CalendarService _calendar;
  String userId;

  StreamSubscription? _remoteTasksSubscription;
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

  TasksNotifier(this._localRepo, this._remoteRepo, this._calendar, this.userId) {
    _tasks = _localRepo.getTasks();
    _initSync();
  }

  void updateDependencies(String newUserId, LocalTaskRepository localRepo, TaskRepository remoteRepo, CalendarService calendar) {
    _localRepo = localRepo;
    _remoteRepo = remoteRepo;
    _calendar = calendar;

    if (userId != newUserId) {
      userId = newUserId;
      _remoteTasksSubscription?.cancel();
      _tasks = _localRepo.getTasks();
      _initSync();
      notifyListeners();
    }
  }

  void _initSync() {
    _remoteTasksSubscription = _remoteRepo.watchTasks().listen(
      (remoteTasks) {
        // Sync remote to local
        for (final rTask in remoteTasks) {
          final localTask = TaskModelHive(
            id: rTask.id,
            userId: rTask.userId,
            title: rTask.title,
            description: rTask.description,
            scheduledAt: rTask.scheduledAt,
            createdAt: rTask.createdAt,
            isCompleted: rTask.isCompleted,
            isSyncedToCalendar: rTask.isSyncedToCalendar,
            calendarEventId: rTask.calendarEventId,
          );
          _localRepo.updateTask(localTask);
        }
        
        refresh();
      },
      onError: (e) {
        debugPrint('Firebase sync error (probably offline): $e');
      },
    );
  }

  @override
  void dispose() {
    _remoteTasksSubscription?.cancel();
    super.dispose();
  }

  void refresh() {
    _tasks = _localRepo.getTasks();
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    String? description,
    required DateTime scheduledAt,
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
      );

      // Save to Local DB First (Offline Support)
      await _localRepo.addTask(localTask);

      // Try calendar sync
      try {
        final eventId = await _calendar.createEvent(localTask);
        localTask = localTask.copyWith(
          isSyncedToCalendar: true,
          calendarEventId: eventId,
        );
        await _localRepo.updateTask(localTask);
      } catch (e) {
        debugPrint('⚠️ Calendar sync failed (task still saved): $e');
      }

      // Save to Firebase (Cloud Support - auto retries when online)
      try {
        final rTask = TaskModel(
          id: localTask.id,
          userId: localTask.userId,
          title: localTask.title,
          description: localTask.description,
          scheduledAt: localTask.scheduledAt,
          createdAt: localTask.createdAt,
          isCompleted: localTask.isCompleted,
          isSyncedToCalendar: localTask.isSyncedToCalendar,
          calendarEventId: localTask.calendarEventId,
        );
        await _remoteRepo.addTask(rTask);
      } catch (e) {
        debugPrint('⚠️ Firebase add failed (offline), saved locally: $e');
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

    // Sync to Firebase
    try {
      final rTask = TaskModel(
        id: updated.id,
        userId: updated.userId,
        title: updated.title,
        description: updated.description,
        scheduledAt: updated.scheduledAt,
        createdAt: updated.createdAt,
        isCompleted: updated.isCompleted,
        isSyncedToCalendar: updated.isSyncedToCalendar,
        calendarEventId: updated.calendarEventId,
      );
      await _remoteRepo.updateTask(rTask);
    } catch (e) {
      debugPrint('⚠️ Firebase toggle failed (offline), toggled locally: $e');
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
    
    // Delete from Firebase
    try {
      await _remoteRepo.deleteTask(task.id);
    } catch (e) {
      debugPrint('⚠️ Firebase delete failed (offline), deleted locally: $e');
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
    
    // Sync to Firebase
    try {
      final rTask = TaskModel(
        id: task.id,
        userId: task.userId,
        title: task.title,
        description: task.description,
        scheduledAt: task.scheduledAt,
        createdAt: task.createdAt,
        isCompleted: task.isCompleted,
        isSyncedToCalendar: task.isSyncedToCalendar,
        calendarEventId: task.calendarEventId,
      );
      await _remoteRepo.updateTask(rTask);
    } catch (e) {
      debugPrint('⚠️ Firebase update failed (offline), updated locally: $e');
    }

    refresh();
  }
}
