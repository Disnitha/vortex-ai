import '../../../core/services/schedule_repository.dart';
import '../../../models/task.dart';

import '../time_blocking/time_block.dart';

import '../optimization/schedule_optimizer.dart';
import '../optimization/schedule_quality_analyzer.dart';


class ScheduleGenerationResult {
  final List<TimeBlock> blocks;
  final ScheduleQualityResult quality;

  const ScheduleGenerationResult({
    required this.blocks,
    required this.quality,
  });
}

class ScheduleGenerationService {
  ScheduleGenerationService({
    ScheduleRepository? scheduleRepository,
    ScheduleOptimizer? optimizer,
  })  : _scheduleRepository =
            scheduleRepository ?? ScheduleRepository.instance,
        _optimizer = optimizer ?? ScheduleOptimizer();


  final ScheduleRepository _scheduleRepository;
  final ScheduleOptimizer _optimizer;

  Future<List<TimeBlock>> generateAndSaveSchedule({
    required List<Task> tasks,
    required DateTime availableStart,
    required DateTime availableEnd,
  }) async {
    final result = await generateScheduleWithQuality(
      tasks: tasks,
      availableStart: availableStart,
      availableEnd: availableEnd,
    );

    return result.blocks;
  }

  Future<ScheduleGenerationResult> generateScheduleWithQuality({
    required List<Task> tasks,
    required DateTime availableStart,
    required DateTime availableEnd,
  }) async {
    final existingScheduledTasks =
        _scheduleRepository.getScheduledTasksForDate(
      availableStart,
    );

    // Generate is a full schedule regeneration.
    // Remove the existing schedule for this day first.
    if (existingScheduledTasks.isNotEmpty) {
      await _scheduleRepository.removeScheduledTasksForDate(
        availableStart,
      );
    }

    final optimizationResult = _optimizer.optimize(
      tasks: tasks,
      availableStart: availableStart,
      availableEnd: availableEnd,
    );

    for (final block in optimizationResult.blocks) {
      await _scheduleRepository.addScheduledTask(
        block.toScheduledTask(),
      );
    }

    return ScheduleGenerationResult(
      blocks: optimizationResult.blocks,
      quality: optimizationResult.quality,
    );
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