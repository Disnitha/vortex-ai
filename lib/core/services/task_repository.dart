import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/task.dart';

class TaskRepository extends ChangeNotifier {
  TaskRepository._();

  static final TaskRepository instance = TaskRepository._();

  static const String _boxName = 'tasks';

  final List<Task> _tasks = [];

  bool _initialized = false;

  List<Task> get tasks => List.unmodifiable(_tasks);

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    final box = await Hive.openBox(_boxName);

    if (box.isEmpty) {
      _tasks.addAll(_defaultTasks());

      await _saveAllTasks();
    } else {
      _tasks.addAll(
        box.values.map(
          (value) => Task.fromMap(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      );
    }

    _initialized = true;
    notifyListeners();
  }

  List<Task> _defaultTasks() {
    return [
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
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);

    await _saveTask(task);

    notifyListeners();
  }

  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere(
      (task) => task.id == updatedTask.id,
    );

    if (index == -1) {
      return;
    }

    _tasks[index] = updatedTask;

    await _saveTask(updatedTask);

    notifyListeners();
  }

  Future<void> removeTask(String taskId) async {
    _tasks.removeWhere(
      (task) => task.id == taskId,
    );

    final box = Hive.box(_boxName);

    await box.delete(taskId);

    notifyListeners();
  }

  Future<void> startTask(String taskId) async {
    await _updateTaskStatus(
      taskId,
      TaskStatus.inProgress,
    );
  }

  Future<void> completeTask(String taskId) async {
    await _updateTaskStatus(
      taskId,
      TaskStatus.completed,
    );
  }

  Future<void> reopenTask(String taskId) async {
    await _updateTaskStatus(
      taskId,
      TaskStatus.pending,
    );
  }

  Future<void> markTaskMissed(String taskId) async {
    await _updateTaskStatus(
      taskId,
      TaskStatus.missed,
    );
  }

  Future<void> _updateTaskStatus(
    String taskId,
    TaskStatus status,
  ) async {
    final index = _tasks.indexWhere(
      (task) => task.id == taskId,
    );

    if (index == -1) {
      return;
    }

    final updatedTask = _tasks[index].copyWith(
      status: status,
    );

    _tasks[index] = updatedTask;

    await _saveTask(updatedTask);

    notifyListeners();
  }

  Future<void> _saveTask(Task task) async {
    final box = Hive.box(_boxName);

    await box.put(
      task.id,
      task.toMap(),
    );
  }

  Future<void> _saveAllTasks() async {
    final box = Hive.box(_boxName);

    await box.clear();

    for (final task in _tasks) {
      await box.put(
        task.id,
        task.toMap(),
      );
    }
  }
}