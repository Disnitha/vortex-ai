import 'package:flutter_test/flutter_test.dart';

import 'package:vortex_ai/features/scheduler/ai_scheduler/scheduling_coordinator.dart';
import 'package:vortex_ai/models/task.dart';
import 'package:vortex_ai/features/scheduler/time_blocking/time_block.dart';

void main() {
  group('SchedulingCoordinator', () {
    test('schedules tasks according to priority without overlap', () {
      final coordinator = SchedulingCoordinator();

      final tasks = [
        Task(
          id: 'low',
          title: 'Low Priority',
          priority: TaskPriority.low,
          estimatedMinutes: 60,
          createdAt: DateTime.now(),
        ),
        Task(
          id: 'urgent',
          title: 'Urgent Task',
          priority: TaskPriority.urgent,
          estimatedMinutes: 60,
          createdAt: DateTime.now(),
        ),
      ];

      final start = DateTime(2026, 9, 22, 9, 0);
      final end = DateTime(2026, 9, 22, 12, 0);

      final result = coordinator.generateSchedule(
        tasks: tasks,
        availableStart: start,
        availableEnd: end,
      );

      expect(result.length, 2);

      expect(result[0].taskId, 'urgent');
      expect(result[0].startTime, start);
      expect(
        result[0].endTime,
        DateTime(2026, 9, 22, 10, 0),
      );

      expect(result[1].taskId, 'low');
      expect(
        result[1].startTime,
        DateTime(2026, 9, 22, 10, 0),
      );
      expect(
        result[1].endTime,
        DateTime(2026, 9, 22, 11, 0),
      );
    });

    test('respects existing scheduled blocks', () {
      final coordinator = SchedulingCoordinator();

      final task = Task(
        id: 'task',
        title: 'Physics Revision',
        priority: TaskPriority.high,
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      final start = DateTime(2026, 9, 22, 9, 0);
      final end = DateTime(2026, 9, 22, 12, 0);

      final existingBlock = TimeBlock(
        id: 'existing',
        taskId: 'existing_task',
        startTime: DateTime(2026, 9, 22, 9, 0),
        endTime: DateTime(2026, 9, 22, 10, 0),
      );

      final result = coordinator.generateSchedule(
        tasks: [task],
        availableStart: start,
        availableEnd: end,
        existingBlocks: [existingBlock],
      );

      expect(result.length, 2);

      expect(
        result[1].taskId,
        'task',
      );

      expect(
        result[1].startTime,
        DateTime(2026, 9, 22, 10, 0),
      );
    });

    test('skips tasks that cannot fit in available time', () {
      final coordinator = SchedulingCoordinator();

      final task = Task(
        id: 'long_task',
        title: 'Long Task',
        priority: TaskPriority.high,
        estimatedMinutes: 180,
        createdAt: DateTime.now(),
      );

      final start = DateTime(2026, 9, 22, 9, 0);
      final end = DateTime(2026, 9, 22, 10, 0);

      final result = coordinator.generateSchedule(
        tasks: [task],
        availableStart: start,
        availableEnd: end,
      );

      expect(result, isEmpty);
    });
  });
}