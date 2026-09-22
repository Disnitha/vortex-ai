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

    for (final task in prioritizedTasks) {
      final timeBlock = _timeBlockingEngine.findAvailableSlot(
        task: task,
        availableStart: availableStart,
        availableEnd: availableEnd,
        existingBlocks: scheduledBlocks,
      );

      if (timeBlock == null) {
        continue;
      }

      // Do not schedule a task if it would finish after its deadline.
      if (task.deadline != null &&
          timeBlock.endTime.isAfter(task.deadline!)) {
        continue;
      }

      scheduledBlocks.add(timeBlock);
    }

    return scheduledBlocks;
  }
}