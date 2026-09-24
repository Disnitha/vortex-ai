import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:vortex_ai/core/services/schedule_repository.dart';
import 'package:vortex_ai/core/services/task_repository.dart';
import 'package:vortex_ai/features/scheduler/rescheduling/missed_task_rescheduling_service.dart';
import 'package:vortex_ai/models/scheduled_task.dart';
import 'package:vortex_ai/models/task.dart';

void main() {
  late Directory testDirectory;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'vortex_ai_rescheduling_test_',
    );

    Hive.init(testDirectory.path);

    await TaskRepository.instance.init();
    await ScheduleRepository.instance.init();
  });

  tearDownAll(() async {
    await Hive.close();

    if (await testDirectory.exists()) {
      await testDirectory.delete(
        recursive: true,
      );
    }
  });

  setUp(() async {
    await ScheduleRepository.instance.clearAll();
  });

  group('MissedTaskReschedulingService', () {
    test('reschedules a missed task into an available slot',
        () async {
      final task = Task(
        id: 'reschedule_task',
        title: 'Physics Revision',
        status: TaskStatus.missed,
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      await TaskRepository.instance.addTask(task);

      final service =
          MissedTaskReschedulingService.instance;

      final start = DateTime(2026, 9, 28, 10, 0);
      final end = DateTime(2026, 9, 28, 14, 0);

      final result = await service.rescheduleTask(
        task: task,
        availableStart: start,
        availableEnd: end,
      );

      expect(result, isNotNull);
      expect(result!.taskId, task.id);
      expect(result.startTime, start);
      expect(
        result.endTime,
        DateTime(2026, 9, 28, 11, 0),
      );

      final savedSchedule =
          ScheduleRepository.instance.getScheduledTaskForTask(
        task.id,
      );

      expect(savedSchedule, isNotNull);
    });

    test('avoids existing scheduled tasks', () async {
      final existingTask = Task(
        id: 'existing_task',
        title: 'ICT Assignment',
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      final missedTask = Task(
        id: 'missed_reschedule_task',
        title: 'Physics Revision',
        status: TaskStatus.missed,
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      await TaskRepository.instance.addTask(existingTask);
      await TaskRepository.instance.addTask(missedTask);

      final start = DateTime(2026, 9, 29, 10, 0);
      final end = DateTime(2026, 9, 29, 14, 0);

      await ScheduleRepository.instance.addScheduledTask(
        ScheduledTask(
          id: 'existing_schedule',
          taskId: existingTask.id,
          startTime: start,
          endTime: DateTime(2026, 9, 29, 11, 0),
        ),
      );

      final result =
          await MissedTaskReschedulingService.instance.rescheduleTask(
        task: missedTask,
        availableStart: start,
        availableEnd: end,
      );

      expect(result, isNotNull);
      expect(
        result!.startTime,
        DateTime(2026, 9, 29, 11, 0),
      );
      expect(
        result.endTime,
        DateTime(2026, 9, 29, 12, 0),
      );
    });

    test('does not reschedule a non-missed task', () async {
      final task = Task(
        id: 'pending_reschedule_task',
        title: 'Pending Task',
        status: TaskStatus.pending,
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      final result =
          await MissedTaskReschedulingService.instance.rescheduleTask(
        task: task,
        availableStart: DateTime(2026, 9, 30, 10, 0),
        availableEnd: DateTime(2026, 9, 30, 14, 0),
      );

      expect(result, isNull);
    });

    test('returns null when no slot is available', () async {
      final existingTask = Task(
        id: 'blocking_task',
        title: 'Blocking Task',
        estimatedMinutes: 120,
        createdAt: DateTime.now(),
      );

      final missedTask = Task(
        id: 'no_slot_task',
        title: 'Missed Task',
        status: TaskStatus.missed,
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      await TaskRepository.instance.addTask(existingTask);
      await TaskRepository.instance.addTask(missedTask);

      final start = DateTime(2026, 10, 1, 10, 0);
      final end = DateTime(2026, 10, 1, 11, 0);

      await ScheduleRepository.instance.addScheduledTask(
        ScheduledTask(
          id: 'blocking_schedule',
          taskId: existingTask.id,
          startTime: start,
          endTime: end,
        ),
      );

      final result =
          await MissedTaskReschedulingService.instance.rescheduleTask(
        task: missedTask,
        availableStart: start,
        availableEnd: end,
      );

      expect(result, isNull);
    });
    test(
        'prefers an earlier available slot for a high priority missed task',
        () async {
      final task = Task(
        id: 'high_priority_missed_task',
        title: 'Urgent Physics Revision',
        status: TaskStatus.missed,
        priority: TaskPriority.high,
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      await TaskRepository.instance.addTask(task);

      final start = DateTime(2026, 10, 2, 10, 0);
      final end = DateTime(2026, 10, 2, 18, 0);

      final result =
          await MissedTaskReschedulingService.instance.rescheduleTask(
        task: task,
        availableStart: start,
        availableEnd: end,
      );

      expect(result, isNotNull);
      expect(result!.startTime, start);
      expect(
        result.endTime,
        DateTime(2026, 10, 2, 11, 0),
      );
    });

    test(
        'does not schedule a missed task beyond its deadline',
        () async {
      final task = Task(
        id: 'deadline_missed_task',
        title: 'Physics Deadline Task',
        status: TaskStatus.missed,
        priority: TaskPriority.high,
        estimatedMinutes: 120,
        deadline: DateTime(2026, 10, 2, 11, 0),
        createdAt: DateTime.now(),
      );

      await TaskRepository.instance.addTask(task);

      final start = DateTime(2026, 10, 2, 10, 0);
      final end = DateTime(2026, 10, 2, 18, 0);

      final result =
          await MissedTaskReschedulingService.instance.rescheduleTask(
        task: task,
        availableStart: start,
        availableEnd: end,
      );

      expect(result, isNull);
    });

    test(
        'uses a later slot when the earlier slot is blocked',
        () async {
      final blockingTask = Task(
        id: 'adaptive_blocking_task',
        title: 'Existing Task',
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      final missedTask = Task(
        id: 'adaptive_missed_task',
        title: 'Missed Physics',
        status: TaskStatus.missed,
        priority: TaskPriority.high,
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      await TaskRepository.instance.addTask(blockingTask);
      await TaskRepository.instance.addTask(missedTask);

      final start = DateTime(2026, 10, 3, 10, 0);
      final end = DateTime(2026, 10, 3, 14, 0);

      await ScheduleRepository.instance.addScheduledTask(
        ScheduledTask(
          id: 'adaptive_blocking_schedule',
          taskId: blockingTask.id,
          startTime: start,
          endTime: DateTime(2026, 10, 3, 11, 0),
        ),
      );

      final result =
          await MissedTaskReschedulingService.instance.rescheduleTask(
        task: missedTask,
        availableStart: start,
        availableEnd: end,
      );

      expect(result, isNotNull);
      expect(
        result!.startTime,
        DateTime(2026, 10, 3, 11, 0),
      );
      expect(
        result.endTime,
        DateTime(2026, 10, 3, 12, 0),
      );
    });
        test(
        'finds a later slot that still meets the deadline',
        () async {
      final blockingTask = Task(
        id: 'deadline_blocking_task',
        title: 'Existing Task',
        estimatedMinutes: 60,
        createdAt: DateTime.now(),
      );

      final missedTask = Task(
        id: 'deadline_later_slot_task',
        title: 'Missed Physics',
        status: TaskStatus.missed,
        priority: TaskPriority.high,
        estimatedMinutes: 60,
        deadline: DateTime(2026, 10, 4, 13, 0),
        createdAt: DateTime.now(),
      );

      await TaskRepository.instance.addTask(blockingTask);
      await TaskRepository.instance.addTask(missedTask);

      final start = DateTime(2026, 10, 4, 10, 0);
      final end = DateTime(2026, 10, 4, 16, 0);

      await ScheduleRepository.instance.addScheduledTask(
        ScheduledTask(
          id: 'deadline_blocking_schedule',
          taskId: blockingTask.id,
          startTime: start,
          endTime: DateTime(2026, 10, 4, 12, 0),
        ),
      );

      final result =
          await MissedTaskReschedulingService.instance.rescheduleTask(
        task: missedTask,
        availableStart: start,
        availableEnd: end,
      );

      expect(result, isNotNull);
      expect(
        result!.startTime,
        DateTime(2026, 10, 4, 12, 0),
      );
      expect(
        result.endTime,
        DateTime(2026, 10, 4, 13, 0),
      );
      expect(
        result.endTime.isBefore(missedTask.deadline!) ||
            result.endTime.isAtSameMomentAs(
              missedTask.deadline!,
            ),
        isTrue,
      );
    });
  });
}