import 'package:flutter_test/flutter_test.dart';

import 'package:vortex_ai/features/scheduler/ai_scheduler/scheduling_coordinator.dart';
import 'package:vortex_ai/features/scheduler/time_blocking/time_block.dart';
import 'package:vortex_ai/models/task.dart';

void main() {
  final coordinator = SchedulingCoordinator();

  group('SchedulingCoordinator', () {
    test('schedules a task when it fits exactly', () {
      final start = DateTime(2026, 9, 23, 8, 0);
      final end = DateTime(2026, 9, 23, 9, 0);

      final task = Task(
        id: '1',
        title: 'One hour task',
        estimatedMinutes: 60,
        createdAt: start,
      );

      final result = coordinator.generateSchedule(
        tasks: [task],
        availableStart: start,
        availableEnd: end,
      );

      expect(result.length, 1);
      expect(result.first.startTime, start);
      expect(result.first.endTime, end);
    });

    test('does not schedule a task that is too long', () {
      final start = DateTime(2026, 9, 23, 8, 0);
      final end = DateTime(2026, 9, 23, 9, 0);

      final task = Task(
        id: '1',
        title: 'Two hour task',
        estimatedMinutes: 120,
        createdAt: start,
      );

      final result = coordinator.generateSchedule(
        tasks: [task],
        availableStart: start,
        availableEnd: end,
      );

      expect(result, isEmpty);
    });

    test('does not create overlapping blocks', () {
      final start = DateTime(2026, 9, 23, 8, 0);
      final end = DateTime(2026, 9, 23, 12, 0);

      final firstTask = Task(
        id: '1',
        title: 'First task',
        estimatedMinutes: 120,
        createdAt: start,
      );

      final secondTask = Task(
        id: '2',
        title: 'Second task',
        estimatedMinutes: 120,
        createdAt: start,
      );

      final result = coordinator.generateSchedule(
        tasks: [firstTask, secondTask],
        availableStart: start,
        availableEnd: end,
      );

      expect(result.length, 2);
      expect(result[0].overlaps(result[1]), isFalse);
    });

    test('respects existing scheduled blocks', () {
      final start = DateTime(2026, 9, 23, 8, 0);
      final end = DateTime(2026, 9, 23, 12, 0);

      final existingBlock = TimeBlock(
        id: 'existing',
        taskId: 'existing-task',
        startTime: DateTime(2026, 9, 23, 8, 0),
        endTime: DateTime(2026, 9, 23, 10, 0),
      );

      final task = Task(
        id: '1',
        title: 'New task',
        estimatedMinutes: 60,
        createdAt: start,
      );

      final result = coordinator.generateSchedule(
        tasks: [task],
        availableStart: start,
        availableEnd: end,
        existingBlocks: [existingBlock],
      );

      expect(result.length, 2);

      final newBlock = result.firstWhere(
        (block) => block.taskId == '1',
      );

      expect(
        newBlock.startTime,
        DateTime(2026, 9, 23, 10, 0),
      );

      expect(
        newBlock.endTime,
        DateTime(2026, 9, 23, 11, 0),
      );
    });

    test('schedules smaller tasks when a larger task cannot fit', () {
      final start = DateTime(2026, 9, 23, 8, 0);
      final end = DateTime(2026, 9, 23, 10, 0);

      final largeTask = Task(
        id: '1',
        title: 'Large task',
        estimatedMinutes: 180,
        priority: TaskPriority.high,
        createdAt: start,
      );

      final smallTask = Task(
        id: '2',
        title: 'Small task',
        estimatedMinutes: 60,
        priority: TaskPriority.medium,
        createdAt: start,
      );

      final result = coordinator.generateSchedule(
        tasks: [largeTask, smallTask],
        availableStart: start,
        availableEnd: end,
      );

      expect(result.length, 1);
      expect(result.first.taskId, '2');
    });
    test('keeps task priority higher than workload balancing', () {
      final start = DateTime(2026, 9, 23, 8, 0);
      final end = DateTime(2026, 9, 23, 13, 0);

      final urgentLongTask = Task(
        id: '1',
        title: 'Urgent long task',
        priority: TaskPriority.urgent,
        estimatedMinutes: 120,
        createdAt: start,
      );

      final lowShortTask = Task(
        id: '2',
        title: 'Short task',
        priority: TaskPriority.low,
        estimatedMinutes: 60,
        createdAt: start,
      );

      final result = coordinator.generateSchedule(
        tasks: [
          urgentLongTask,
          lowShortTask,
        ],
        availableStart: start,
        availableEnd: end,
      );

      expect(result.length, 2);
      expect(result.first.taskId, '1');
      expect(result.first.startTime, start);
    });

  test('schedules multiple tasks without overlap', () {
    final start = DateTime(2026, 9, 23, 8, 0);
    final end = DateTime(2026, 9, 23, 14, 0);

    final tasks = [
      Task(
        id: '1',
        title: 'Long task',
        priority: TaskPriority.high,
        estimatedMinutes: 120,
        createdAt: start,
      ),
      Task(
        id: '2',
        title: 'Short task',
        priority: TaskPriority.medium,
        estimatedMinutes: 60,
        createdAt: start,
      ),
      Task(
        id: '3',
        title: 'Another task',
        priority: TaskPriority.medium,
        estimatedMinutes: 120,
        createdAt: start,
      ),
    ];

    final result = coordinator.generateSchedule(
      tasks: tasks,
      availableStart: start,
      availableEnd: end,
    );

    for (var i = 0; i < result.length; i++) {
      for (var j = i + 1; j < result.length; j++) {
        expect(
          result[i].overlaps(result[j]),
          isFalse,
        );
      }
    }
  });

  test('respects urgent deadline over workload preference', () {
    final start = DateTime(2026, 9, 23, 8, 0);
    final end = DateTime(2026, 9, 23, 13, 0);

    final now = DateTime.now();

    final urgentTask = Task(
      id: '1',
      title: 'Urgent task',
      priority: TaskPriority.medium,
      estimatedMinutes: 120,
      deadline: now.add(
        const Duration(hours: 4),
      ),
      createdAt: start,
    );

    final shortTask = Task(
      id: '2',
      title: 'Short task',
      priority: TaskPriority.medium,
      estimatedMinutes: 30,
      deadline: now.add(
        const Duration(days: 2),
      ),
      createdAt: start,
    );

    final result = coordinator.generateSchedule(
      tasks: [
        shortTask,
        urgentTask,
      ],
      availableStart: start,
      availableEnd: end,
    );

    expect(result.length, 2);
    expect(result.first.taskId, '1');
    });
  });
}