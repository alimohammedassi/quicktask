// lib/presentation/providers/current_task_provider.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_service.dart';
import '../../core/database/task_model_hive.dart';
import '../../data/repositories/subtask_repository.dart';
import '../../domain/models/subtask.dart';

class CurrentTaskNotifier extends ChangeNotifier {
  String? _currentTaskId;
  TaskModelHive? _currentTask;

  CurrentTaskNotifier() {
    _currentTaskId = DatabaseService.currentTaskId;
  }

  String? get currentTaskId => _currentTaskId;
  TaskModelHive? get currentTask => _currentTask;

  // ── Subtasks for the current task ───────────────────────────
  List<SubTask> get subtasks {
    if (_currentTaskId == null) return [];
    return SubtaskRepository.getSubtasks(_currentTaskId!).map((m) => SubTask(
          id: m['id'] as String,
          title: m['title'] as String,
          isCompleted: m['done'] as bool,
        )).toList();
  }

  double get progress {
    final subs = subtasks;
    if (subs.isEmpty) return 0;
    return subs.where((s) => s.isCompleted).length / subs.length;
  }

  int get completedCount => subtasks.where((s) => s.isCompleted).length;
  int get totalCount => subtasks.length;

  /// Set which task is "current" (hero card)
  Future<void> setCurrentTask(TaskModelHive task) async {
    _currentTaskId = task.id;
    _currentTask = task;
    await DatabaseService.setCurrentTaskId(task.id);
    notifyListeners();
  }

  /// Update list of all tasks from TasksNotifier and sync state
  void updateTasks(List<TaskModelHive> allTasks) {
    if (_currentTaskId == null) return;
    try {
      final task = allTasks.firstWhere((t) => t.id == _currentTaskId);
      if (task.isCompleted) {
        _currentTask = null;
        _currentTaskId = null;
        DatabaseService.setCurrentTaskId(null);
        notifyListeners();
      } else {
        if (_currentTask?.id != task.id || _currentTask?.isCompleted != task.isCompleted || _currentTask?.title != task.title || _currentTask?.categories != task.categories) {
          _currentTask = task;
          notifyListeners();
        }
      }
    } catch (_) {
      // ONLY clear the current task if the tasks list is actually NOT empty.
      // This prevents wiping out the current task if the database is temporarily empty or loading.
      if (allTasks.isNotEmpty) {
        _currentTask = null;
        _currentTaskId = null;
        DatabaseService.setCurrentTaskId(null);
        notifyListeners();
      }
    }
  }

  /// Refresh the internal task reference (deprecated, replaced by updateTasks)
  void refreshTask(List<TaskModelHive> allTasks) {
    // Left empty for compatibility, handled automatically by updateTasks
  }

  /// Clear current task selection
  Future<void> clearCurrentTask() async {
    _currentTaskId = null;
    _currentTask = null;
    await DatabaseService.setCurrentTaskId(null);
    notifyListeners();
  }

  // ── Subtask CRUD ────────────────────────────────────────────
  Future<void> addSubtask(String taskId, String title) async {
    final id = const Uuid().v4().substring(0, 8);
    await SubtaskRepository.addSubtask(taskId, id, title);
    notifyListeners();
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    await SubtaskRepository.toggleSubtask(taskId, subtaskId);
    notifyListeners();
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    await SubtaskRepository.deleteSubtask(taskId, subtaskId);
    notifyListeners();
  }

  /// Get subtasks for any task (not just current)
  List<SubTask> subtasksForTask(String taskId) {
    return SubtaskRepository.getSubtasks(taskId).map((m) => SubTask(
          id: m['id'] as String,
          title: m['title'] as String,
          isCompleted: m['done'] as bool,
        )).toList();
  }

  double progressForTask(String taskId) => SubtaskRepository.getProgress(taskId);
}
