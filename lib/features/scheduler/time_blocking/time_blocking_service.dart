import '../../../core/services/schedule_repository.dart';
import '../../../models/task.dart';
import 'time_block.dart';
import 'time_blocking_engine.dart';

class TimeBlockingService {
  TimeBlockingService._();

  static final TimeBlockingService instance = TimeBlockingService._();

  final TimeBlockingEngine _engine = TimeBlockingEngine();

  Future<TimeBlock?> scheduleTask({
    required Task task,
    required DateTime availableStart,
    required DateTime availableEnd,
  }) async {
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

    final timeBlock = _engine.findAvailableSlot(
      task: task,
      availableStart: availableStart,
      availableEnd: availableEnd,
      existingBlocks: existingBlocks,
    );

    if (timeBlock == null) {
      return null;
    }

    await ScheduleRepository.instance.addScheduledTask(
      timeBlock.toScheduledTask(),
    );

    return timeBlock;
  }
}