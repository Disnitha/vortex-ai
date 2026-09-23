import 'package:flutter_test/flutter_test.dart';

import 'package:vortex_ai/features/scheduler/ai_scheduler/daily_planning_service.dart';
import 'package:vortex_ai/models/task.dart';
import 'package:vortex_ai/features/scheduler/time_blocking/time_block.dart';

void main() {
  late DailyPlanningService service;

  setUp(() {
    service = DailyPlanningService();
  });

  test('creates a daily plan for pending tasks', () {
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

    final plan = service.createDailyPlan(
      tasks: tasks,
      availableStart: start,
      availableEnd: end,
    );

    expect(plan.length, 2);
    expect(plan[0].taskId, '1');
    expect(plan[1].taskId, '2');
  });

  test('does not schedule tasks outside available time', () {
    final start = DateTime(2026, 9, 22, 8, 0);
    final end = DateTime(2026, 9, 22, 7, 0);

    final tasks = [
      Task(
        id: '1',
        title: 'Physics',
        estimatedMinutes: 60,
        createdAt: start,
      ),
    ];

    final plan = service.createDailyPlan(
      tasks: tasks,
      availableStart: start,
      availableEnd: end,
    );

    expect(plan, isEmpty);
  });

  test('returns empty plan when there are no tasks', () {
    final start = DateTime(2026, 9, 22, 8, 0);
    final end = DateTime(2026, 9, 22, 18, 0);

    final plan = service.createDailyPlan(
      tasks: [],
      availableStart: start,
      availableEnd: end,
    );

    expect(plan, isEmpty);
  });

  test('respects existing scheduled blocks', () {
    final start = DateTime(2026, 9, 22, 8, 0);
    final end = DateTime(2026, 9, 22, 12, 0);

    final existingBlock = TimeBlock(
      id: 'existing',
      taskId: 'existing-task',
      startTime: DateTime(2026, 9, 22, 8, 0),
      endTime: DateTime(2026, 9, 22, 9, 0),
    );

    final tasks = [
      Task(
        id: '1',
        title: 'Physics',
        estimatedMinutes: 60,
        createdAt: start,
      ),
    ];

    final plan = service.createDailyPlan(
      tasks: tasks,
      availableStart: start,
      availableEnd: end,
      existingBlocks: [existingBlock],
    );

    expect(plan.length, 2);

    expect(
      plan.any(
        (block) => block.taskId == 'existing-task',
      ),
      isTrue,
    );

    final scheduledTask = plan.firstWhere(
      (block) => block.taskId == '1',
    );

    expect(
      scheduledTask.startTime,
      DateTime(2026, 9, 22, 9, 0),
    );

    expect(
      scheduledTask.endTime,
      DateTime(2026, 9, 22, 10, 0),
    );
  });
}