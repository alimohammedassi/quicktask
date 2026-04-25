// lib/data/repositories/local_task_repository.dart
import 'package:flutter/foundation.dart';
import '../../core/database/database_service.dart';
import '../../core/database/task_model_hive.dart';

class LocalTaskRepository {
  final String userId;

  LocalTaskRepository({required this.userId});

  List<TaskModelHive> getTasks() {
    return DatabaseService.getTasksForUser(userId);
  }

  TaskModelHive? getTask(String taskId) {
    return DatabaseService.getTask(taskId);
  }

  Future<void> addTask(TaskModelHive task) async {
    await DatabaseService.saveTask(task);
  }

  Future<void> updateTask(TaskModelHive task) async {
    await DatabaseService.saveTask(task);
  }

  Future<void> deleteTask(String taskId) async {
    await DatabaseService.deleteTask(taskId);
  }

  Future<void> toggleComplete(String taskId) async {
    final task = DatabaseService.getTask(taskId);
    if (task != null) {
      await DatabaseService.saveTask(task.copyWith(isCompleted: !task.isCompleted));
    }
  }

  Future<void> clearAllTasks() async {
    await DatabaseService.deleteTasksForUser(userId);
  }
}
