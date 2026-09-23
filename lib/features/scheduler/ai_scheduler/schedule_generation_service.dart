import '../../../core/services/schedule_repository.dart';
import '../../../models/task.dart';
import '../time_blocking/time_block.dart';
import 'scheduling_coordinator.dart';

class ScheduleGenerationService {
  ScheduleGenerationService({
    SchedulingCoordinator? coordinator,
    ScheduleRepository? scheduleRepository,
  })  : _coordinator = coordinator ?? SchedulingCoordinator(),
        _scheduleRepository =
            scheduleRepository ?? ScheduleRepository.instance;

  final SchedulingCoordinator _coordinator;
  final ScheduleRepository _scheduleRepository;

  Future<List<TimeBlock>> generateAndSaveSchedule({
    required List<Task> tasks,
    required DateTime availableStart,
    required DateTime availableEnd,
  }) async {
    final existingScheduledTasks =
        _scheduleRepository.getScheduledTasksForDate(
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

    // Tasks that are already scheduled for this day
    // should not be scheduled again.
    final scheduledTaskIds = existingScheduledTasks
        .map((scheduledTask) => scheduledTask.taskId)
        .toSet();

    final unscheduledTasks = tasks.where((task) {
      return !scheduledTaskIds.contains(task.id);
    }).toList();

    if (unscheduledTasks.isEmpty) {
      return [];
    }

    final generatedBlocks = _coordinator.generateSchedule(
      tasks: unscheduledTasks,
      availableStart: availableStart,
      availableEnd: availableEnd,
      existingBlocks: existingBlocks,
    );

    final newBlocks = generatedBlocks.where((block) {
      return !existingBlocks.any(
        (existingBlock) =>
            existingBlock.id == block.id ||
            existingBlock.taskId == block.taskId,
      );
    }).toList();

    for (final block in newBlocks) {
      await _scheduleRepository.addScheduledTask(
        block.toScheduledTask(),
      );
    }

    return newBlocks;
  }

  Future<TimeBlock?> scheduleTaskAutomatically({
    required Task task,
    required DateTime availableStart,
    required DateTime availableEnd,
  }) async {
    final generatedBlocks = await generateAndSaveSchedule(
      tasks: [task],
      availableStart: availableStart,
      availableEnd: availableEnd,
    );

    if (generatedBlocks.isEmpty) {
      return null;
    }

    return generatedBlocks.first;
  }
}