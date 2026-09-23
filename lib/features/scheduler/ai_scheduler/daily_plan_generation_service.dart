import '../../../core/services/schedule_repository.dart';
import '../../../models/task.dart';
import '../time_blocking/time_block.dart';
import 'daily_planning_service.dart';

class DailyPlanGenerationService {
  DailyPlanGenerationService({
    DailyPlanningService? planningService,
    ScheduleRepository? scheduleRepository,
  })  : _planningService =
            planningService ?? DailyPlanningService(),
        _scheduleRepository =
            scheduleRepository ?? ScheduleRepository.instance;

  final DailyPlanningService _planningService;
  final ScheduleRepository _scheduleRepository;

  Future<List<TimeBlock>> generateAndSaveDailyPlan({
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

    final generatedPlan = _planningService.createDailyPlan(
      tasks: tasks,
      availableStart: availableStart,
      availableEnd: availableEnd,
      existingBlocks: existingBlocks,
    );

    final newBlocks = generatedPlan.where((block) {
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
}