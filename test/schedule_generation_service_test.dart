import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:vortex_ai/core/services/schedule_repository.dart';
import 'package:vortex_ai/features/scheduler/ai_scheduler/schedule_generation_service.dart';
import 'package:vortex_ai/models/task.dart';

void main() {
  late Directory testDirectory;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'vortex_ai_test_',
    );

    Hive.init(testDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();

    if (await testDirectory.exists()) {
      await testDirectory.delete(
        recursive: true,
      );
    }
  });

  group('ScheduleGenerationService', () {
    test('generates and saves scheduled tasks', () async {
      final repository = ScheduleRepository.instance;

      await repository.init();

      final service = ScheduleGenerationService(
        scheduleRepository: repository,
      );

      final task = Task(
        id: 'schedule_test_task',
        title: 'Physics Revision',
        priority: TaskPriority.high,
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      final start = DateTime(2026, 9, 22, 9, 0);
      final end = DateTime(2026, 9, 22, 12, 0);

      final result = await service.generateAndSaveSchedule(
        tasks: [task],
        availableStart: start,
        availableEnd: end,
      );

      expect(result.length, 1);
      expect(result.first.taskId, task.id);

      final savedTasks =
          repository.getScheduledTasksForDate(start);

      expect(
        savedTasks.any(
          (scheduledTask) => scheduledTask.taskId == task.id,
        ),
        isTrue,
      );
    });

    test('generates another schedule without crashing', () async {
      final repository = ScheduleRepository.instance;

      final service = ScheduleGenerationService(
        scheduleRepository: repository,
      );

      final task = Task(
        id: 'second_test_task',
        title: 'ICT Assignment',
        priority: TaskPriority.medium,
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      final start = DateTime(2026, 9, 23, 9, 0);
      final end = DateTime(2026, 9, 23, 12, 0);

      final result = await service.generateAndSaveSchedule(
        tasks: [task],
        availableStart: start,
        availableEnd: end,
      );

      expect(result, isNotEmpty);
    });

    test('automatically schedules a task into an available slot', () async {
      final service = ScheduleGenerationService();

      final task = Task(
        id: 'auto_task',
        title: 'Automatic Task',
        priority: TaskPriority.high,
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      final start = DateTime(2026, 9, 24, 9, 0);
      final end = DateTime(2026, 9, 24, 12, 0);

      final result = await service.scheduleTaskAutomatically(
        task: task,
        availableStart: start,
        availableEnd: end,
      );

      expect(result, isNotNull);
      expect(result!.taskId, 'auto_task');
      expect(result.startTime, start);
      expect(
        result.endTime,
          DateTime(2026, 9, 24, 10, 0),
      );
    });

    test('does not automatically schedule a task after its deadline',
        () async {
      final service = ScheduleGenerationService();

      final task = Task(
        id: 'deadline_task',
        title: 'Deadline Task',
        priority: TaskPriority.high,
        estimatedMinutes: 60,
        deadline: DateTime(2026, 9, 25, 9, 30),
        createdAt: DateTime.now(),
      );

      final start = DateTime(2026, 9, 25, 9, 0);
      final end = DateTime(2026, 9, 25, 12, 0);

      final result = await service.scheduleTaskAutomatically(
        task: task,
        availableStart: start,
        availableEnd: end,
      );

      expect(result, isNull);
    });
    test('reschedules an edited task with its updated duration', () async {
      final repository = ScheduleRepository.instance;

      final service = ScheduleGenerationService(
        scheduleRepository: repository,
      );

      final originalTask = Task(
        id: 'edit_schedule_task',
        title: 'Physics Revision',
        priority: TaskPriority.high,
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      final start = DateTime(2026, 9, 26, 9, 0);
      final end = DateTime(2026, 9, 26, 14, 0);

      final originalSchedule =
          await service.scheduleTaskAutomatically(
        task: originalTask,
        availableStart: start,
        availableEnd: end,
      );

      expect(originalSchedule, isNotNull);
      expect(
        originalSchedule!.endTime,
        DateTime(2026, 9, 26, 10, 0),
      );

      await repository.removeScheduledTask(
        originalSchedule.id,
      );

      final updatedTask = originalTask.copyWith(
        estimatedMinutes: 180,
      );

      final updatedSchedule =
          await service.scheduleTaskAutomatically(
        task: updatedTask,
        availableStart: start,
        availableEnd: end,
      );

      expect(updatedSchedule, isNotNull);
      expect(
        updatedSchedule!.startTime,
        DateTime(2026, 9, 26, 9, 0),
      );
      expect(
        updatedSchedule.endTime,
        DateTime(2026, 9, 26, 12, 0),
      );
    });
  });
}