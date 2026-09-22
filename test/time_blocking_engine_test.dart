import 'package:flutter_test/flutter_test.dart';

import 'package:vortex_ai/features/scheduler/time_blocking/time_block.dart';
import 'package:vortex_ai/features/scheduler/time_blocking/time_blocking_engine.dart';
import 'package:vortex_ai/models/task.dart';

void main() {
  group('TimeBlockingEngine', () {
    test('finds the earliest available slot', () {
      final engine = TimeBlockingEngine();

      final task = Task(
        id: 'task_1',
        title: 'Physics Revision',
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      final start = DateTime(2026, 9, 22, 9, 0);
      final end = DateTime(2026, 9, 22, 12, 0);

      final result = engine.findAvailableSlot(
        task: task,
        availableStart: start,
        availableEnd: end,
        existingBlocks: [],
      );

      expect(result, isNotNull);
      expect(result!.startTime, start);
      expect(
        result.endTime,
        DateTime(2026, 9, 22, 10, 0),
      );
    });

    test('avoids an existing time block', () {
      final engine = TimeBlockingEngine();

      final task = Task(
        id: 'task_2',
        title: 'ICT Assignment',
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

      final result = engine.findAvailableSlot(
        task: task,
        availableStart: start,
        availableEnd: end,
        existingBlocks: [existingBlock],
      );

      expect(result, isNotNull);
      expect(
        result!.startTime,
        DateTime(2026, 9, 22, 10, 0),
      );
      expect(
        result.endTime,
        DateTime(2026, 9, 22, 11, 0),
      );
    });

    test('returns null when there is not enough time', () {
      final engine = TimeBlockingEngine();

      final task = Task(
        id: 'task_3',
        title: 'Mathematics Practice',
        estimatedMinutes: 120,
        createdAt: DateTime.now(),
      );

      final start = DateTime(2026, 9, 22, 9, 0);
      final end = DateTime(2026, 9, 22, 10, 0);

      final result = engine.findAvailableSlot(
        task: task,
        availableStart: start,
        availableEnd: end,
        existingBlocks: [],
      );

      expect(result, isNull);
    });
  });
}