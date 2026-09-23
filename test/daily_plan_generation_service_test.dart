import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:vortex_ai/core/services/schedule_repository.dart';
import 'package:vortex_ai/features/scheduler/ai_scheduler/daily_plan_generation_service.dart';
import 'package:vortex_ai/models/task.dart';

void main() {
  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp(
      'vortex_ai_test',
    );

    Hive.init(directory.path);

    await ScheduleRepository.instance.init();
  });

  setUp(() async {
    await ScheduleRepository.instance.clearAll();
  });

  test('generates and saves a daily plan', () async {
    final start = DateTime(2026, 9, 22, 8, 0);
    final end = DateTime(2026, 9, 22, 12, 0);

    final tasks = [
      Task(
        id: '1',
        title: 'Physics',
        priority: TaskPriority.high,
        estimatedMinutes: 60,
        createdAt: start,
      ),
      Task(
        id: '2',
        title: 'ICT',
        priority: TaskPriority.medium,
        estimatedMinutes: 60,
        createdAt: start,
      ),
    ];

    final service = DailyPlanGenerationService();

    final plan = await service.generateAndSaveDailyPlan(
      tasks: tasks,
      availableStart: start,
      availableEnd: end,
    );

    expect(plan.length, 2);

    final savedTasks =
        ScheduleRepository.instance.getScheduledTasksForDate(start);

    expect(savedTasks.length, 2);
  });

  test('does not duplicate existing scheduled blocks', () async {
    final start = DateTime(2026, 9, 22, 8, 0);
    final end = DateTime(2026, 9, 22, 12, 0);

    final task = Task(
      id: '1',
      title: 'Physics',
      estimatedMinutes: 60,
      createdAt: start,
    );

    final service = DailyPlanGenerationService();

    await service.generateAndSaveDailyPlan(
      tasks: [task],
      availableStart: start,
      availableEnd: end,
    );

    final firstCount =
        ScheduleRepository.instance.getScheduledTasksForDate(start).length;

    await service.generateAndSaveDailyPlan(
      tasks: [task],
      availableStart: start,
      availableEnd: end,
    );

    final secondCount =
        ScheduleRepository.instance.getScheduledTasksForDate(start).length;

    expect(firstCount, 1);
    expect(secondCount, 1);
  });

  test('respects existing scheduled tasks', () async {
    final start = DateTime(2026, 9, 22, 8, 0);
    final end = DateTime(2026, 9, 22, 12, 0);

    final existingTask = Task(
      id: 'existing',
      title: 'Existing Task',
      estimatedMinutes: 60,
      createdAt: start,
    );

    final newTask = Task(
      id: 'new',
      title: 'New Task',
      estimatedMinutes: 60,
      createdAt: start,
    );

    final service = DailyPlanGenerationService();

    await service.generateAndSaveDailyPlan(
      tasks: [existingTask],
      availableStart: start,
      availableEnd: end,
    );

    final plan = await service.generateAndSaveDailyPlan(
      tasks: [newTask],
      availableStart: start,
      availableEnd: end,
    );

    expect(plan.length, 1);
    expect(plan.first.taskId, 'new');
    expect(
      plan.first.startTime,
      DateTime(2026, 9, 22, 9, 0),
    );

    final savedTasks =
        ScheduleRepository.instance.getScheduledTasksForDate(start);

    expect(savedTasks.length, 2);
  });
}