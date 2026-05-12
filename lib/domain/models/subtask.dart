// lib/domain/models/subtask.dart

class SubTask {
  final String id;
  final String title;
  final bool isCompleted;

  const SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  SubTask copyWith({String? id, String? title, bool? isCompleted}) => SubTask(
        id: id ?? this.id,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

class CurrentTask {
  final String title;
  final String category1;
  final String category2;
  final List<SubTask> subtasks;

  const CurrentTask({
    required this.title,
    required this.category1,
    required this.category2,
    required this.subtasks,
  });

  double get progressPercent =>
      subtasks.isEmpty ? 0 : subtasks.where((s) => s.isCompleted).length / subtasks.length;

  int get completedCount => subtasks.where((s) => s.isCompleted).length;
  int get totalCount => subtasks.length;

  CurrentTask copyWith({
    String? title,
    String? category1,
    String? category2,
    List<SubTask>? subtasks,
  }) =>
      CurrentTask(
        title: title ?? this.title,
        category1: category1 ?? this.category1,
        category2: category2 ?? this.category2,
        subtasks: subtasks ?? this.subtasks,
      );
}
