import 'package:flutter/foundation.dart';

import '../../models/task.dart';

class TaskRepository extends ChangeNotifier {
  TaskRepository._();

  static final TaskRepository instance = TaskRepository._();

  final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Physics Revision',
      category: 'Study',
      priority: TaskPriority.high,
      estimatedMinutes: 90,
      createdAt: DateTime.now(),
    ),
    Task(
      id: '2',
      title: 'ICT Assignment',
      category: 'Study',
      priority: TaskPriority.medium,
      estimatedMinutes: 60,
      createdAt: DateTime.now(),
    ),
    Task(
      id: '3',
      title: 'Mathematics Practice',
      category: 'Study',
      priority: TaskPriority.urgent,
      estimatedMinutes: 120,
      createdAt: DateTime.now(),
    ),
  ];

  List<Task> get tasks => List.unmodifiable(_tasks);

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void removeTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
  }
}