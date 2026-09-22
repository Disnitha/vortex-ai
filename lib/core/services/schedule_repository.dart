import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/scheduled_task.dart';

class ScheduleRepository extends ChangeNotifier {
  Future<void> removeScheduledTasksForDate(DateTime date) async {
    final tasksForDate = getScheduledTasksForDate(date);

    final box = Hive.box(_boxName);

    for (final scheduledTask in tasksForDate) {
      await box.delete(scheduledTask.id);
    }

    _scheduledTasks.removeWhere((scheduledTask) {
      return scheduledTask.startTime.year == date.year &&
          scheduledTask.startTime.month == date.month &&
          scheduledTask.startTime.day == date.day;
    });

    notifyListeners();
  }
  ScheduleRepository._();

  static final ScheduleRepository instance = ScheduleRepository._();

  static const String _boxName = 'scheduled_tasks';

  final List<ScheduledTask> _scheduledTasks = [];

  bool _initialized = false;

  List<ScheduledTask> get scheduledTasks =>
      List.unmodifiable(_scheduledTasks);

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    final box = await Hive.openBox(_boxName);

    _scheduledTasks.clear();

    for (final value in box.values) {
      _scheduledTasks.add(
        ScheduledTask.fromMap(
          Map<String, dynamic>.from(value as Map),
        ),
      );
    }

    _initialized = true;

    notifyListeners();
  }

  Future<void> addScheduledTask(
    ScheduledTask scheduledTask,
  ) async {
    _scheduledTasks.add(scheduledTask);

    await _saveScheduledTask(scheduledTask);

    notifyListeners();
  }

  Future<void> updateScheduledTask(
    ScheduledTask updatedTask,
  ) async {
    final index = _scheduledTasks.indexWhere(
      (scheduledTask) => scheduledTask.id == updatedTask.id,
    );

    if (index == -1) {
      return;
    }

    _scheduledTasks[index] = updatedTask;

    await _saveScheduledTask(updatedTask);

    notifyListeners();
  }

  Future<void> removeScheduledTask(String scheduledTaskId) async {
    _scheduledTasks.removeWhere(
      (scheduledTask) => scheduledTask.id == scheduledTaskId,
    );

    final box = Hive.box(_boxName);

    await box.delete(scheduledTaskId);

    notifyListeners();
  }

  List<ScheduledTask> getScheduledTasksForDate(DateTime date) {
    return _scheduledTasks.where((scheduledTask) {
      return scheduledTask.startTime.year == date.year &&
          scheduledTask.startTime.month == date.month &&
          scheduledTask.startTime.day == date.day;
    }).toList();
  }

  Future<void> _saveScheduledTask(
    ScheduledTask scheduledTask,
  ) async {
    final box = Hive.box(_boxName);

    await box.put(
      scheduledTask.id,
      scheduledTask.toMap(),
    );
  }
}