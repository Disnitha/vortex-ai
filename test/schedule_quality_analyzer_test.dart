import 'package:flutter_test/flutter_test.dart';

import 'package:vortex_ai/features/scheduler/optimization/schedule_quality_analyzer.dart';
import 'package:vortex_ai/features/scheduler/time_blocking/time_block.dart';
import 'package:vortex_ai/models/task.dart';

void main() {
  group('ScheduleQualityAnalyzer', () {
    test('returns perfect score for a fully scheduled clean plan', () {
      final tasks = [
        Task(
          id: 'physics',
          title: 'Physics',
          estimatedMinutes: 60,
          createdAt: DateTime(2026, 10, 5),
        ),
        Task(
          id: 'ict',
          title: 'ICT',
          estimatedMinutes: 60,
          createdAt: DateTime(2026, 10, 5),
        ),
      ];

      final blocks = [
        TimeBlock(
          id: 'block_1',
          taskId: 'physics',
          startTime: DateTime(2026, 10, 5, 10, 0),
          endTime: DateTime(2026, 10, 5, 11, 0),
        ),
        TimeBlock(
          id: 'block_2',
          taskId: 'ict',
          startTime: DateTime(2026, 10, 5, 12, 0),
          endTime: DateTime(2026, 10, 5, 13, 0),
        ),
      ];

      final analyzer = ScheduleQualityAnalyzer();

      final result = analyzer.analyze(
        tasks: tasks,
        scheduledBlocks: blocks,
        availableStart: DateTime(2026, 10, 5, 10, 0),
        availableEnd: DateTime(2026, 10, 5, 14, 0),
      );

      expect(result.taskCoverage, 100);
      expect(result.deadlineSafety, 100);
      expect(result.conflictScore, 100);
      expect(result.overallScore, greaterThan(80));
    });

    test('detects unscheduled tasks', () {
      final tasks = [
        Task(
          id: 'physics',
          title: 'Physics',
          estimatedMinutes: 60,
          createdAt: DateTime(2026, 10, 5),
        ),
        Task(
          id: 'ict',
          title: 'ICT',
          estimatedMinutes: 60,
          createdAt: DateTime(2026, 10, 5),
        ),
      ];

      final blocks = [
        TimeBlock(
          id: 'block_1',
          taskId: 'physics',
          startTime: DateTime(2026, 10, 5, 10, 0),
          endTime: DateTime(2026, 10, 5, 11, 0),
        ),
      ];

      final analyzer = ScheduleQualityAnalyzer();

      final result = analyzer.analyze(
        tasks: tasks,
        scheduledBlocks: blocks,
        availableStart: DateTime(2026, 10, 5, 10, 0),
        availableEnd: DateTime(2026, 10, 5, 14, 0),
      );

      expect(result.taskCoverage, 50);
      expect(result.overallScore, lessThan(100));
    });

    test('detects a task scheduled beyond its deadline', () {
      final tasks = [
        Task(
          id: 'physics',
          title: 'Physics',
          estimatedMinutes: 120,
          deadline: DateTime(2026, 10, 5, 11, 0),
          createdAt: DateTime(2026, 10, 5),
        ),
      ];

      final blocks = [
        TimeBlock(
          id: 'block_1',
          taskId: 'physics',
          startTime: DateTime(2026, 10, 5, 10, 0),
          endTime: DateTime(2026, 10, 5, 12, 0),
        ),
      ];

      final analyzer = ScheduleQualityAnalyzer();

      final result = analyzer.analyze(
        tasks: tasks,
        scheduledBlocks: blocks,
        availableStart: DateTime(2026, 10, 5, 10, 0),
        availableEnd: DateTime(2026, 10, 5, 14, 0),
      );

      expect(result.deadlineSafety, 0);
      expect(result.overallScore, lessThan(100));
    });

    test('detects overlapping scheduled blocks', () {
      final tasks = [
        Task(
          id: 'physics',
          title: 'Physics',
          estimatedMinutes: 60,
          createdAt: DateTime(2026, 10, 5),
        ),
        Task(
          id: 'maths',
          title: 'Mathematics',
          estimatedMinutes: 60,
          createdAt: DateTime(2026, 10, 5),
        ),
      ];

      final blocks = [
        TimeBlock(
          id: 'block_1',
          taskId: 'physics',
          startTime: DateTime(2026, 10, 5, 10, 0),
          endTime: DateTime(2026, 10, 5, 11, 0),
        ),
        TimeBlock(
          id: 'block_2',
          taskId: 'maths',
          startTime: DateTime(2026, 10, 5, 10, 30),
          endTime: DateTime(2026, 10, 5, 11, 30),
        ),
      ];

      final analyzer = ScheduleQualityAnalyzer();

      final result = analyzer.analyze(
        tasks: tasks,
        scheduledBlocks: blocks,
        availableStart: DateTime(2026, 10, 5, 10, 0),
        availableEnd: DateTime(2026, 10, 5, 14, 0),
      );

      expect(result.conflictScore, lessThan(100));
      expect(result.overallScore, lessThan(100));
    });

    test('returns zero coverage when there are no scheduled tasks', () {
      final tasks = [
        Task(
          id: 'physics',
          title: 'Physics',
          estimatedMinutes: 60,
          createdAt: DateTime(2026, 10, 5),
        ),
      ];

      final analyzer = ScheduleQualityAnalyzer();

      final result = analyzer.analyze(
        tasks: tasks,
        scheduledBlocks: const [],
        availableStart: DateTime(2026, 10, 5, 10, 0),
        availableEnd: DateTime(2026, 10, 5, 14, 0),
      );

      expect(result.taskCoverage, 0);
      expect(result.overallScore, lessThan(100));
    });
  });
}