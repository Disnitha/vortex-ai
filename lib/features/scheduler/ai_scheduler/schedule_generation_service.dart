import '../../../core/services/schedule_repository.dart';
import '../../../models/task.dart';
import '../optimization/schedule_quality_analyzer.dart';
import '../time_blocking/time_block.dart';
import 'scheduling_coordinator.dart';

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
    SchedulingCoordinator? coordinator,
    ScheduleRepository? scheduleRepository,
    ScheduleQualityAnalyzer? qualityAnalyzer,
  })  : _coordinator = coordinator ?? SchedulingCoordinator(),
        _scheduleRepository =
            scheduleRepository ?? ScheduleRepository.instance,
        _qualityAnalyzer =
            qualityAnalyzer ?? ScheduleQualityAnalyzer();

  final SchedulingCoordinator _coordinator;
  final ScheduleRepository _scheduleRepository;
  final ScheduleQualityAnalyzer _qualityAnalyzer;

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

    final generatedBlocks = _coordinator.generateSchedule(
      tasks: tasks,
      availableStart: availableStart,
      availableEnd: availableEnd,
    );

    for (final block in generatedBlocks) {
      await _scheduleRepository.addScheduledTask(
        block.toScheduledTask(),
      );
    }

    final quality = _qualityAnalyzer.analyze(
      tasks: tasks,
      scheduledBlocks: generatedBlocks,
      availableStart: availableStart,
      availableEnd: availableEnd,
    );

    return ScheduleGenerationResult(
      blocks: generatedBlocks,
      quality: quality,
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