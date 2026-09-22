import '../../../core/services/task_repository.dart';
import '../../../core/services/schedule_repository.dart';
import '../../../models/task.dart';

class MissedTaskService {
  MissedTaskService._();

  static final MissedTaskService instance = MissedTaskService._();

  Future<int> detectMissedTasks({
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();

    final taskRepository = TaskRepository.instance;
    final scheduleRepository = ScheduleRepository.instance;

    var missedCount = 0;

    for (final scheduledTask
        in scheduleRepository.scheduledTasks) {
      if (!scheduledTask.endTime.isBefore(currentTime)) {
        continue;
      }

      final task = taskRepository.tasks.firstWhere(
        (task) => task.id == scheduledTask.taskId,
        orElse: () => throw StateError(
          'Task not found: ${scheduledTask.taskId}',
        ),
      );

      if (task.status == TaskStatus.completed ||
          task.status == TaskStatus.missed) {
        continue;
      }

      await taskRepository.markTaskMissed(task.id);

      missedCount++;
    }

    return missedCount;
  }
}