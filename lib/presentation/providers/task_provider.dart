// lib/presentation/providers/task_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/task_model_hive.dart';
import '../../data/repositories/local_task_repository.dart';
import '../../services/calendar_service.dart';
import '../../services/notification_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/models/task_model.dart';

// ─── Local Task Repository Provider ─────────────────────────────────────────

final localTaskRepositoryProvider = Provider<LocalTaskRepository>((ref) {
  final authState = ref.watch(authStateStreamProvider);
  final user = authState.valueOrNull;
  // TEMP: Fall back to a guest repo during UI testing (no auth)
  return LocalTaskRepository(userId: user?.uid ?? 'guest');
});

// ─── Calendar Service Provider ───────────────────────────────────────────────

final calendarServiceProvider = Provider<CalendarService>((ref) {
  // CalendarService needs the concrete impl for getAccessCredentials()
  final authRepo = ref.watch(authRepositoryProvider);
  return CalendarService(authRepo);
});

// ─── Task Repository Provider ─────────────────────────────────────────────────

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final authState = ref.watch(authStateStreamProvider);
  final user = authState.valueOrNull;
  return TaskRepository(userId: user?.uid ?? 'guest');
});

// ─── Tasks Notifier (local Hive + Firebase Sync) ────────────────────────────

class TasksNotifier extends StateNotifier<List<TaskModelHive>> {
  final LocalTaskRepository _localRepo;
  final TaskRepository _remoteRepo;
  final CalendarService _calendar;
  final String userId;

  StreamSubscription? _remoteTasksSubscription;

  TasksNotifier(this._localRepo, this._remoteRepo, this._calendar, this.userId)
      : super(_localRepo.getTasks()) {
    _initSync();
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
        
        // Remove local tasks that are not in remote (if you want full mirrored state)
        // To prevent overriding unsynced local tasks, we skip deletion logic for now
        // and just update/add what comes from Firebase.

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
    state = _localRepo.getTasks();
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

final tasksNotifierProvider =
    StateNotifierProvider<TasksNotifier, List<TaskModelHive>>((ref) {
  final localRepo = ref.watch(localTaskRepositoryProvider);
  final remoteRepo = ref.watch(taskRepositoryProvider);
  final calendar = ref.watch(calendarServiceProvider);
  final authState = ref.watch(authStateStreamProvider);
  final user = authState.valueOrNull;

  // TEMP: Use 'guest' userId during UI testing (no auth)
  return TasksNotifier(localRepo, remoteRepo, calendar, user?.uid ?? 'guest');
});

// ─── Derived providers ────────────────────────────────────────────────────────

final completedTasksProvider = Provider<List<TaskModelHive>>((ref) {
  final tasks = ref.watch(tasksNotifierProvider);
  return tasks.where((t) => t.isCompleted).toList();
});

final pendingTasksProvider = Provider<List<TaskModelHive>>((ref) {
  final tasks = ref.watch(tasksNotifierProvider);
  return tasks.where((t) => !t.isCompleted).toList();
});

final upcomingTasksProvider = Provider<List<TaskModelHive>>((ref) {
  final tasks = ref.watch(pendingTasksProvider);
  final now = DateTime.now();
  return tasks.where((t) => t.scheduledAt.isAfter(now)).toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
});

final overdueTasksProvider = Provider<List<TaskModelHive>>((ref) {
  final tasks = ref.watch(pendingTasksProvider);
  final now = DateTime.now();
  return tasks.where((t) => t.scheduledAt.isBefore(now)).toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
});
