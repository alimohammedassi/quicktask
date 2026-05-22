// lib/core/database/database_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'user_model.dart';
import 'task_model_hive.dart';
import '../../data/repositories/subtask_repository.dart';

class DatabaseService {
  static const String _usersBox = 'users';
  static const String _tasksBox = 'tasks';
  static const String _prefsBox = 'prefs';
  static const String _settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(TaskModelHiveAdapter());

    // Open boxes
    await Hive.openBox<UserModel>(_usersBox);
    await Hive.openBox<TaskModelHive>(_tasksBox);
    await Hive.openBox<String>(_prefsBox);
    await Hive.openBox(_settingsBox);
    await SubtaskRepository.init();
  }

  static Box<UserModel> get usersBox => Hive.box<UserModel>(_usersBox);
  static Box<TaskModelHive> get tasksBox => Hive.box<TaskModelHive>(_tasksBox);
  static Box<String> get prefsBox => Hive.box<String>(_prefsBox);
  static Box get settingsBox => Hive.box(_settingsBox);

  // ── Current task preference ─────────────────────────────────
  static String? get currentTaskId => prefsBox.get('currentTaskId');
  static Future<void> setCurrentTaskId(String? id) async {
    if (id == null) {
      await prefsBox.delete('currentTaskId');
    } else {
      await prefsBox.put('currentTaskId', id);
    }
  }

  // ─── User operations ─────────────────────────────────────────────────────────

  static Future<void> saveUser(UserModel user) async {
    await usersBox.put(user.uid, user);
  }

  static UserModel? getUser(String uid) {
    return usersBox.get(uid);
  }

  static UserModel? get currentUser {
    if (usersBox.isEmpty) return null;
    return usersBox.values.first;
  }

  static Future<void> deleteUser(String uid) async {
    await usersBox.delete(uid);
  }

  static Future<void> clearUsers() async {
    await usersBox.clear();
  }

  // ─── Task operations ────────────────────────────────────────────────────────

  static List<TaskModelHive> getTasksForUser(String userId) {
    return tasksBox.values
        .where((t) => t.userId == userId)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  static Future<void> saveTask(TaskModelHive task) async {
    await tasksBox.put(task.id, task);
  }

  static TaskModelHive? getTask(String taskId) {
    return tasksBox.get(taskId);
  }

  static Future<void> deleteTask(String taskId) async {
    await tasksBox.delete(taskId);
  }

  static Future<void> deleteTasksForUser(String userId) async {
    final keys = tasksBox.values
        .where((t) => t.userId == userId)
        .map((t) => t.id)
        .toList();
    await tasksBox.deleteAll(keys);
  }

  static Future<void> clearAllTasks() async {
    await tasksBox.clear();
  }

  // ─── Cleanup ────────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    await usersBox.clear();
    await tasksBox.clear();
  }
}
