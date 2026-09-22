import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:vortex_ai/core/services/schedule_repository.dart';
import 'package:vortex_ai/core/services/task_repository.dart';
import 'package:vortex_ai/features/scheduler/rescheduling/missed_task_service.dart';
import 'package:vortex_ai/models/scheduled_task.dart';
import 'package:vortex_ai/models/task.dart';

void main() {
  late Directory testDirectory;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'vortex_ai_missed_task_test_',
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

  group('MissedTaskService', () {

    setUp(() async {
      await ScheduleRepository.instance.clearAll();
    });

    test('marks a pending task as missed after its schedule ends',
        () async {
      final task = Task(
        id: 'missed_pending_task',
        title: 'Physics Revision',
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
      );

      await TaskRepository.instance.addTask(task);

      final scheduledTask = ScheduledTask(
        id: 'schedule_missed_pending',
        taskId: task.id,
        startTime: DateTime(2026, 9, 27, 9, 0),
        endTime: DateTime(2026, 9, 27, 10, 0),
      );

      await ScheduleRepository.instance.addScheduledTask(
        scheduledTask,
      );

      final missedCount =
          await MissedTaskService.instance.detectMissedTasks(
        now: DateTime(2026, 9, 27, 11, 0),
      );

      expect(missedCount, 1);
      expect(
        TaskRepository.instance.tasks
            .firstWhere((task) => task.id == 'missed_pending_task')
            .status,
        TaskStatus.missed,
      );
    });

    test('marks an in-progress task as missed after its schedule ends',
        () async {
      final task = Task(
        id: 'missed_progress_task',
        title: 'ICT Assignment',
        status: TaskStatus.inProgress,
        createdAt: DateTime.now(),
      );

      await TaskRepository.instance.addTask(task);

      await ScheduleRepository.instance.addScheduledTask(
        ScheduledTask(
          id: 'schedule_missed_progress',
          taskId: task.id,
          startTime: DateTime(2026, 9, 27, 9, 0),
          endTime: DateTime(2026, 9, 27, 10, 0),
        ),
      );

      final missedCount =
          await MissedTaskService.instance.detectMissedTasks(
        now: DateTime(2026, 9, 27, 11, 0),
      );

      expect(missedCount, 1);
      expect(
        TaskRepository.instance.tasks
            .firstWhere((task) => task.id == 'missed_progress_task')
            .status,
        TaskStatus.missed,
      );
    });

    test('does not mark a completed task as missed', () async {
      final task = Task(
        id: 'completed_task',
        title: 'Completed Task',
        status: TaskStatus.completed,
        createdAt: DateTime.now(),
      );

      await TaskRepository.instance.addTask(task);

      await ScheduleRepository.instance.addScheduledTask(
        ScheduledTask(
          id: 'schedule_completed',
          taskId: task.id,
          startTime: DateTime(2026, 9, 27, 9, 0),
          endTime: DateTime(2026, 9, 27, 10, 0),
        ),
      );

      final missedCount =
          await MissedTaskService.instance.detectMissedTasks(
        now: DateTime(2026, 9, 27, 11, 0),
      );

      expect(missedCount, 0);
      expect(
        TaskRepository.instance.tasks
            .firstWhere((task) => task.id == 'completed_task')
            .status,
        TaskStatus.completed,
      );
    });

    test('does not mark a future task as missed', () async {
      final task = Task(
        id: 'future_task',
        title: 'Future Task',
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
      );

      await TaskRepository.instance.addTask(task);

      await ScheduleRepository.instance.addScheduledTask(
        ScheduledTask(
          id: 'schedule_future',
          taskId: task.id,
          startTime: DateTime(2026, 9, 27, 12, 0),
          endTime: DateTime(2026, 9, 27, 13, 0),
        ),
      );

      final missedCount =
          await MissedTaskService.instance.detectMissedTasks(
        now: DateTime(2026, 9, 27, 11, 0),
      );

      expect(missedCount, 0);
      expect(
        TaskRepository.instance.tasks
            .firstWhere((task) => task.id == 'future_task')
            .status,
        TaskStatus.pending,
      );
    });

    test('does not process an already missed task again', () async {
      final task = Task(
        id: 'already_missed_task',
        title: 'Already Missed',
        status: TaskStatus.missed,
        createdAt: DateTime.now(),
      );

      await TaskRepository.instance.addTask(task);

      await ScheduleRepository.instance.addScheduledTask(
        ScheduledTask(
          id: 'schedule_already_missed',
          taskId: task.id,
          startTime: DateTime(2026, 9, 27, 9, 0),
          endTime: DateTime(2026, 9, 27, 10, 0),
        ),
      );

      final missedCount =
          await MissedTaskService.instance.detectMissedTasks(
        now: DateTime(2026, 9, 27, 11, 0),
      );

      expect(missedCount, 0);
      expect(
        TaskRepository.instance.tasks
            .firstWhere(
              (task) => task.id == 'already_missed_task',
            )
            .status,
        TaskStatus.missed,
      );
    });

    test(
      'marks a task missed and creates a new schedule',
      () async {
        final task = Task(
          id: 'auto_reschedule_task',
          title: 'Physics Revision',
          status: TaskStatus.pending,
          estimatedMinutes: 60,
          createdAt: DateTime.now(),
        );

        await TaskRepository.instance.addTask(task);

        final oldSchedule = ScheduledTask(
          id: 'old_schedule',
          taskId: task.id,
          startTime: DateTime(2026, 10, 2, 9, 0),
          endTime: DateTime(2026, 10, 2, 10, 0),
        );

        await ScheduleRepository.instance.addScheduledTask(
          oldSchedule,
        );

        final missedCount =
            await MissedTaskService.instance.detectMissedTasks(
          now: DateTime(2026, 10, 2, 11, 0),
        );

        expect(missedCount, 1);

        final updatedTask =
            TaskRepository.instance.tasks.firstWhere(
          (storedTask) => storedTask.id == task.id,
        );

        expect(updatedTask.status, TaskStatus.missed);

        final schedules =
            ScheduleRepository.instance.scheduledTasks.where(
          (scheduledTask) => scheduledTask.taskId == task.id,
        ).toList();

        expect(schedules.length, 1);
        expect(schedules.first.id, isNot(oldSchedule.id));
        expect(
          schedules.first.startTime.isAfter(
            oldSchedule.endTime,
          ),
          isTrue,
        );
      },
    );
  });
}