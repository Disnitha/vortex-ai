import 'package:flutter_test/flutter_test.dart';

import 'package:vortex_ai/features/scheduler/ai_scheduler/ai_scheduler.dart';
import 'package:vortex_ai/models/task.dart';

void main() {
  group('AiScheduler', () {
    test('prioritizes urgent tasks before lower priority tasks', () {
      final scheduler = const AiScheduler();

      final tasks = [
        Task(
          id: '1',
          title: 'Low Priority',
          priority: TaskPriority.low,
          createdAt: DateTime.now(),
        ),
        Task(
          id: '2',
          title: 'Urgent Task',
          priority: TaskPriority.urgent,
          createdAt: DateTime.now(),
        ),
        Task(
          id: '3',
          title: 'High Priority',
          priority: TaskPriority.high,
          createdAt: DateTime.now(),
        ),
      ];

      final result = scheduler.prioritizeTasks(tasks);

      expect(result[0].title, 'Urgent Task');
      expect(result[1].title, 'High Priority');
      expect(result[2].title, 'Low Priority');
    });

    test('uses deadline when priorities are equal', () {
      final scheduler = const AiScheduler();

      final tasks = [
        Task(
          id: '1',
          title: 'Later Task',
          priority: TaskPriority.high,
          deadline: DateTime(2026, 9, 25),
          createdAt: DateTime.now(),
        ),
        Task(
          id: '2',
          title: 'Earlier Task',
          priority: TaskPriority.high,
          deadline: DateTime(2026, 9, 23),
          createdAt: DateTime.now(),
        ),
      ];

      final result = scheduler.prioritizeTasks(tasks);

      expect(result[0].title, 'Earlier Task');
      expect(result[1].title, 'Later Task');
    });

    test('excludes completed and missed tasks', () {
      final scheduler = const AiScheduler();

      final tasks = [
        Task(
          id: '1',
          title: 'Completed Task',
          status: TaskStatus.completed,
          createdAt: DateTime.now(),
        ),
        Task(
          id: '2',
          title: 'Missed Task',
          status: TaskStatus.missed,
          createdAt: DateTime.now(),
        ),
        Task(
          id: '3',
          title: 'Pending Task',
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        ),
      ];

      final result = scheduler.prioritizeTasks(tasks);

      expect(result.length, 1);
      expect(result[0].title, 'Pending Task');
    });
  });
}