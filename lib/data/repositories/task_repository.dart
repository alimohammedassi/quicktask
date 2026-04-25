// lib/data/repositories/task_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  TaskRepository({required this.userId});

  CollectionReference get _tasksRef =>
      _db.collection('users').doc(userId).collection('tasks');

  Stream<List<TaskModel>> watchTasks() {
    return _tasksRef
        .orderBy('scheduledAt')
        .snapshots()
        .handleError((error) {
      throw Exception('Failed to watch tasks: $error');
    })
        .map((snap) => snap.docs.map(TaskModel.fromFirestore).toList());
  }

  Future<String> addTask(TaskModel task) async {
    try {
      await _tasksRef.doc(task.id).set(task.toFirestore());
      return task.id;
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _tasksRef.doc(task.id).set(task.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksRef.doc(taskId).delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }
}
