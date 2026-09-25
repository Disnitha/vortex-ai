import '../../../models/task.dart';
import '../ai_scheduler/scheduling_coordinator.dart';
import '../time_blocking/time_block.dart';
import 'schedule_quality_analyzer.dart';

class ScheduleOptimizationResult {
  final List<TimeBlock> blocks;
  final ScheduleQualityResult quality;

  const ScheduleOptimizationResult({
    required this.blocks,
    required this.quality,
  });
}

class ScheduleOptimizer {
  ScheduleOptimizer({
    SchedulingCoordinator? coordinator,
    ScheduleQualityAnalyzer? qualityAnalyzer,
  })  : _coordinator =
            coordinator ?? SchedulingCoordinator(),
        _qualityAnalyzer =
            qualityAnalyzer ?? ScheduleQualityAnalyzer();

  final SchedulingCoordinator _coordinator;
  final ScheduleQualityAnalyzer _qualityAnalyzer;

  ScheduleOptimizationResult optimize({
    required List<Task> tasks,
    required DateTime availableStart,
    required DateTime availableEnd,
  }) {
    final candidates = <List<TimeBlock>>[];

    // Candidate 1: normal AI priority schedule.
    final prioritySchedule = _coordinator.generateSchedule(
      tasks: tasks,
      availableStart: availableStart,
      availableEnd: availableEnd,
    );

    candidates.add(prioritySchedule);

    // Candidate 2: shortest tasks first.
    final shortestFirstTasks = [...tasks]
      ..sort(
        (a, b) => a.estimatedMinutes.compareTo(
          b.estimatedMinutes,
        ),
      );

    candidates.add(
      _coordinator.generateSchedule(
        tasks: shortestFirstTasks,
        availableStart: availableStart,
        availableEnd: availableEnd,
        preserveTaskOrder: true,
      ),
    );

    // Candidate 3: longest tasks first.
    final longestFirstTasks = [...tasks]
      ..sort(
        (a, b) => b.estimatedMinutes.compareTo(
          a.estimatedMinutes,
        ),
      );

    candidates.add(
      _coordinator.generateSchedule(
        tasks: longestFirstTasks,
        availableStart: availableStart,
        availableEnd: availableEnd,
        preserveTaskOrder: true,
      ),
    );

    List<TimeBlock>? bestBlocks;
    ScheduleQualityResult? bestQuality;

    for (final candidate in candidates) {
      final quality = _qualityAnalyzer.analyze(
        tasks: tasks,
        scheduledBlocks: candidate,
        availableStart: availableStart,
        availableEnd: availableEnd,
      );

      if (bestQuality == null ||
          quality.overallScore > bestQuality.overallScore) {
        bestBlocks = candidate;
        bestQuality = quality;
      }
    }

    return ScheduleOptimizationResult(
      blocks: bestBlocks ?? const [],
      quality: bestQuality ??
          _qualityAnalyzer.analyze(
            tasks: tasks,
            scheduledBlocks: const [],
            availableStart: availableStart,
            availableEnd: availableEnd,
          ),
    );
  }
}