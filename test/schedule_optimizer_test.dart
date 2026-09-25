import 'package:flutter_test/flutter_test.dart';

import 'package:vortex_ai/features/scheduler/optimization/schedule_optimizer.dart';
import 'package:vortex_ai/models/task.dart';

void main() {
  group('ScheduleOptimizer', () {
    test('returns an optimized schedule', () {
      final optimizer = ScheduleOptimizer();

      final tasks = [
        Task(
          id: 'physics',
          title: 'Physics',
          priority: TaskPriority.high,
          estimatedMinutes: 120,
          createdAt: DateTime.now(),
        ),
        Task(
          id: 'ict',
          title: 'ICT',
          priority: TaskPriority.medium,
          estimatedMinutes: 60,
          createdAt: DateTime.now(),
        ),
        Task(
          id: 'maths',
          title: 'Mathematics',
          priority: TaskPriority.urgent,
          estimatedMinutes: 90,
          createdAt: DateTime.now(),
        ),
      ];

      final start = DateTime(
        2026,
        10,
        10,
        7,
        0,
      );

      final end = DateTime(
        2026,
        10,
        10,
        23,
        59,
      );

      final result = optimizer.optimize(
        tasks: tasks,
        availableStart: start,
        availableEnd: end,
      );

      expect(result.blocks, isNotEmpty);
      expect(result.quality.overallScore, inInclusiveRange(0, 100));
    });

    test('does not create overlapping blocks', () {
      final optimizer = ScheduleOptimizer();

      final tasks = [
        Task(
          id: 'task_1',
          title: 'Task 1',
          estimatedMinutes: 120,
          createdAt: DateTime.now(),
        ),
        Task(
          id: 'task_2',
          title: 'Task 2',
          estimatedMinutes: 120,
          createdAt: DateTime.now(),
        ),
        Task(
          id: 'task_3',
          title: 'Task 3',
          estimatedMinutes: 120,
          createdAt: DateTime.now(),
        ),
      ];

      final start = DateTime(
        2026,
        10,
        11,
        7,
        0,
      );

      final end = DateTime(
        2026,
        10,
        11,
        13,
        0,
      );

      final result = optimizer.optimize(
        tasks: tasks,
        availableStart: start,
        availableEnd: end,
      );

      for (var i = 0; i < result.blocks.length; i++) {
        for (var j = i + 1; j < result.blocks.length; j++) {
          expect(
            result.blocks[i].overlaps(result.blocks[j]),
            isFalse,
          );
        }
      }
    });

    test('respects task deadlines', () {
      final optimizer = ScheduleOptimizer();

      final deadline = DateTime(
        2026,
        10,
        12,
        8,
        0,
      );

      final task = Task(
        id: 'deadline_task',
        title: 'Deadline Task',
        priority: TaskPriority.high,
        estimatedMinutes: 120,
        deadline: deadline,
        createdAt: DateTime.now(),
      );

      final result = optimizer.optimize(
        tasks: [task],
        availableStart: DateTime(
          2026,
          10,
          12,
          7,
          0,
        ),
        availableEnd: DateTime(
          2026,
          10,
          12,
          23,
          59,
        ),
      );

      expect(result.blocks, isEmpty);
    });
  });
}