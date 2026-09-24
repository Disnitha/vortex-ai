import '../../../core/services/schedule_repository.dart';
import '../../../models/task.dart';
import '../time_blocking/time_block.dart';
import '../time_blocking/time_blocking_engine.dart';

class MissedTaskReschedulingService {
  MissedTaskReschedulingService._();

  static final MissedTaskReschedulingService instance =
      MissedTaskReschedulingService._();

  final TimeBlockingEngine _timeBlockingEngine =
      TimeBlockingEngine();

  Future<TimeBlock?> rescheduleTask({
    required Task task,
    required DateTime availableStart,
    required DateTime availableEnd,
  }) async {
    if (task.status != TaskStatus.missed) {
      return null;
    }

    final existingScheduledTasks =
        ScheduleRepository.instance.getScheduledTasksForDate(
      availableStart,
    );

    final existingBlocks = existingScheduledTasks.map(
      (scheduledTask) {
        return TimeBlock(
          id: scheduledTask.id,
          taskId: scheduledTask.taskId,
          startTime: scheduledTask.startTime,
          endTime: scheduledTask.endTime,
        );
      },
    ).toList();

    final timeBlock = _timeBlockingEngine.findAvailableSlot(
      task: task,
      availableStart: availableStart,
      availableEnd: availableEnd,
      existingBlocks: existingBlocks,
    );

    if (timeBlock == null) {
      return null;
    }

    // Never reschedule a task beyond its deadline.
    if (task.deadline != null &&
        timeBlock.endTime.isAfter(task.deadline!)) {
      return null;
    }

    await ScheduleRepository.instance.addScheduledTask(
      timeBlock.toScheduledTask(),
    );

    return timeBlock;
  }

  Future<TimeBlock?> rescheduleTaskAutomatically(
    Task task, {
    DateTime? now,
  }) async {
    if (task.status != TaskStatus.missed) {
      return null;
    }

    final currentTime = now ?? DateTime.now();

    final availableStart = currentTime.add(
      const Duration(minutes: 15),
    );

    final availableEnd = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      23,
      59,
    );

    if (!availableStart.isBefore(availableEnd)) {
      return null;
    }

    return rescheduleTask(
      task: task,
      availableStart: availableStart,
      availableEnd: availableEnd,
    );
  }
}