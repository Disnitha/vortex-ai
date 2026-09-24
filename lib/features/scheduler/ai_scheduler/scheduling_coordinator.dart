import '../../../models/task.dart';
import '../time_blocking/time_block.dart';
import '../time_blocking/time_blocking_engine.dart';
import 'ai_scheduler.dart';

class SchedulingCoordinator {
  SchedulingCoordinator({
    AiScheduler? scheduler,
    TimeBlockingEngine? timeBlockingEngine,
  })  : _scheduler = scheduler ?? const AiScheduler(),
        _timeBlockingEngine =
            timeBlockingEngine ?? TimeBlockingEngine();

  final AiScheduler _scheduler;
  final TimeBlockingEngine _timeBlockingEngine;

  List<TimeBlock> generateSchedule({
    required List<Task> tasks,
    required DateTime availableStart,
    required DateTime availableEnd,
    List<TimeBlock> existingBlocks = const [],
  }) {
    final prioritizedTasks = _scheduler.prioritizeTasks(tasks);

    final scheduledBlocks = <TimeBlock>[
      ...existingBlocks,
    ];

    final remainingTasks = <Task>[
      ...prioritizedTasks,
    ];

    int? lastTaskDuration;

    while (remainingTasks.isNotEmpty) {
      final task = _selectNextTask(
        remainingTasks: remainingTasks,
        lastTaskDuration: lastTaskDuration,
      );

      if (task == null) {
        break;
      }

      final timeBlock = _timeBlockingEngine.findAvailableSlot(
        task: task,
        availableStart: availableStart,
        availableEnd: availableEnd,
        existingBlocks: scheduledBlocks,
      );

      remainingTasks.remove(task);

      if (timeBlock == null) {
        continue;
      }

      // Never schedule a task beyond its deadline.
      if (task.deadline != null &&
          timeBlock.endTime.isAfter(task.deadline!)) {
        continue;
      }

      scheduledBlocks.add(timeBlock);

      lastTaskDuration = task.estimatedMinutes;
    }

    return scheduledBlocks;
  }

  Task? _selectNextTask({
    required List<Task> remainingTasks,
    required int? lastTaskDuration,
  }) {
    if (remainingTasks.isEmpty) {
      return null;
    }

    // Deadline tasks always take priority.
    final deadlineTasks = remainingTasks.where(
      (task) => task.deadline != null,
    ).toList();

    if (deadlineTasks.isNotEmpty) {
      deadlineTasks.sort((a, b) {
        return a.deadline!.compareTo(b.deadline!);
      });

      return deadlineTasks.first;
    }

    // After a long task, prefer a shorter task to create
    // a more balanced workload.
    if (lastTaskDuration != null &&
        lastTaskDuration >= 90) {
      final shorterTasks = remainingTasks.where((task) {
        return task.estimatedMinutes < lastTaskDuration!;
      }).toList();

      if (shorterTasks.isNotEmpty) {
        shorterTasks.sort((a, b) {
          return a.estimatedMinutes.compareTo(
            b.estimatedMinutes,
          );
        });

        return shorterTasks.first;
      }
    }

    // Otherwise preserve the AI scheduler's priority order.
    return remainingTasks.first;
  }
}