import '../../../models/task.dart';
import '../time_blocking/time_block.dart';
import 'scheduling_coordinator.dart';

class DailyPlanningService {
  DailyPlanningService({
    SchedulingCoordinator? coordinator,
  }) : _coordinator = coordinator ?? SchedulingCoordinator();

  final SchedulingCoordinator _coordinator;

  List<TimeBlock> createDailyPlan({
    required List<Task> tasks,
    required DateTime availableStart,
    required DateTime availableEnd,
    List<TimeBlock> existingBlocks = const [],
  }) {
    if (tasks.isEmpty) {
      return [];
    }

    if (!availableStart.isBefore(availableEnd)) {
      return [];
    }

    return _coordinator.generateSchedule(
      tasks: tasks,
      availableStart: availableStart,
      availableEnd: availableEnd,
      existingBlocks: existingBlocks,
    );
  }
}