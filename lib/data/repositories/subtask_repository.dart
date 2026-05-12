// lib/data/repositories/subtask_repository.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Stores checklist items per task using a plain Hive box (no adapter needed).
/// Box stores JSON-encoded list of subtask maps keyed by taskId.
class SubtaskRepository {
  static const _boxName = 'subtasks';

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  static Box<String> get _box => Hive.box<String>(_boxName);

  /// Get subtasks for a task
  static List<Map<String, dynamic>> getSubtasks(String taskId) {
    final raw = _box.get(taskId);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  /// Save subtasks for a task
  static Future<void> saveSubtasks(String taskId, List<Map<String, dynamic>> subtasks) async {
    await _box.put(taskId, jsonEncode(subtasks));
  }

  /// Add a subtask
  static Future<void> addSubtask(String taskId, String subtaskId, String title) async {
    final list = getSubtasks(taskId);
    list.add({'id': subtaskId, 'title': title, 'done': false});
    await saveSubtasks(taskId, list);
  }

  /// Toggle a subtask
  static Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final list = getSubtasks(taskId);
    for (final item in list) {
      if (item['id'] == subtaskId) {
        item['done'] = !(item['done'] as bool);
        break;
      }
    }
    await saveSubtasks(taskId, list);
  }

  /// Delete a subtask
  static Future<void> deleteSubtask(String taskId, String subtaskId) async {
    final list = getSubtasks(taskId);
    list.removeWhere((s) => s['id'] == subtaskId);
    await saveSubtasks(taskId, list);
  }

  /// Delete all subtasks for a task
  static Future<void> deleteAllForTask(String taskId) async {
    await _box.delete(taskId);
  }

  /// Get progress (0.0 – 1.0)
  static double getProgress(String taskId) {
    final list = getSubtasks(taskId);
    if (list.isEmpty) return 0;
    return list.where((s) => s['done'] == true).length / list.length;
  }

  /// Count completed
  static int completedCount(String taskId) {
    return getSubtasks(taskId).where((s) => s['done'] == true).length;
  }
}
