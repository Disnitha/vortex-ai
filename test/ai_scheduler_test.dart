import 'package:flutter_test/flutter_test.dart';

import 'package:vortex_ai/features/scheduler/ai_scheduler/ai_scheduler.dart';
import 'package:vortex_ai/models/task.dart';

void main() {
  const scheduler = AiScheduler();

  group('AiScheduler', () {
    test('prioritizes tasks with closer deadlines', () {
      final now = DateTime.now();

      final laterDeadlineTask = Task(
        id: '1',
        title: 'Later deadline',
        priority: TaskPriority.medium,
        estimatedMinutes: 60,
        deadline: now.add(
          const Duration(hours: 48),
        ),
        createdAt: now,
      );

      final urgentDeadlineTask = Task(
        id: '2',
        title: 'Urgent deadline',
        priority: TaskPriority.medium,
        estimatedMinutes: 60,
        deadline: now.add(
          const Duration(hours: 4),
        ),
        createdAt: now,
      );

      final result = scheduler.prioritizeTasks([
        laterDeadlineTask,
        urgentDeadlineTask,
      ]);

      expect(result.first.id, '2');
      expect(result[1].id, '1');
    });

    test('tasks with deadlines come before tasks without deadlines', () {
      final now = DateTime.now();

      final noDeadlineTask = Task(
        id: '1',
        title: 'No deadline',
        priority: TaskPriority.urgent,
        estimatedMinutes: 60,
        createdAt: now,
      );

      final deadlineTask = Task(
        id: '2',
        title: 'Has deadline',
        priority: TaskPriority.low,
        estimatedMinutes: 60,
        deadline: now.add(
          const Duration(days: 2),
        ),
        createdAt: now,
      );

      final result = scheduler.prioritizeTasks([
        noDeadlineTask,
        deadlineTask,
      ]);

      expect(result.first.id, '2');
      expect(result[1].id, '1');
    });

    test('ignores completed and missed tasks', () {
      final now = DateTime.now();

      final pendingTask = Task(
        id: '1',
        title: 'Pending',
        createdAt: now,
      );

      final completedTask = Task(
        id: '2',
        title: 'Completed',
        status: TaskStatus.completed,
        createdAt: now,
      );

      final missedTask = Task(
        id: '3',
        title: 'Missed',
        status: TaskStatus.missed,
        createdAt: now,
      );

      final result = scheduler.prioritizeTasks([
        pendingTask,
        completedTask,
        missedTask,
      ]);

      expect(result.length, 1);
      expect(result.first.id, '1');
    });
  });
}