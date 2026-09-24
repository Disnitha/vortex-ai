import '../../../models/task.dart';
import '../time_blocking/time_block.dart';

class ScheduleQualityResult {
  final int taskCoverage;
  final int deadlineSafety;
  final int conflictScore;
  final int workloadBalance;
  final int timeUtilization;
  final int overallScore;

  const ScheduleQualityResult({
    required this.taskCoverage,
    required this.deadlineSafety,
    required this.conflictScore,
    required this.workloadBalance,
    required this.timeUtilization,
    required this.overallScore,
  });
}

class ScheduleQualityAnalyzer {
  ScheduleQualityResult analyze({
    required List<Task> tasks,
    required List<TimeBlock> scheduledBlocks,
    required DateTime availableStart,
    required DateTime availableEnd,
  }) {
    final taskCoverage = _calculateTaskCoverage(
      tasks,
      scheduledBlocks,
    );

    final deadlineSafety = _calculateDeadlineSafety(
      tasks,
      scheduledBlocks,
    );

    final conflictScore = _calculateConflictScore(
      scheduledBlocks,
    );

    final workloadBalance = _calculateWorkloadBalance(
      scheduledBlocks,
      tasks,
    );

    final timeUtilization = _calculateTimeUtilization(
      scheduledBlocks,
      availableStart,
      availableEnd,
    );

    final overallScore = _calculateOverallScore(
      taskCoverage: taskCoverage,
      deadlineSafety: deadlineSafety,
      conflictScore: conflictScore,
      workloadBalance: workloadBalance,
      timeUtilization: timeUtilization,
    );

    return ScheduleQualityResult(
      taskCoverage: taskCoverage,
      deadlineSafety: deadlineSafety,
      conflictScore: conflictScore,
      workloadBalance: workloadBalance,
      timeUtilization: timeUtilization,
      overallScore: overallScore,
    );
  }

  int _calculateTaskCoverage(
    List<Task> tasks,
    List<TimeBlock> scheduledBlocks,
  ) {
    if (tasks.isEmpty) {
      return 100;
    }

    final scheduledTaskIds = scheduledBlocks
        .map((block) => block.taskId)
        .toSet();

    final scheduledCount = tasks.where(
      (task) => scheduledTaskIds.contains(task.id),
    ).length;

    return ((scheduledCount / tasks.length) * 100)
        .round()
        .clamp(0, 100);
  }

  int _calculateDeadlineSafety(
    List<Task> tasks,
    List<TimeBlock> scheduledBlocks,
  ) {
    final tasksWithDeadlines = tasks.where(
      (task) => task.deadline != null,
    ).toList();

    if (tasksWithDeadlines.isEmpty) {
      return 100;
    }

    var safeTasks = 0;

    for (final task in tasksWithDeadlines) {
      final block = _findBlockForTask(
        task.id,
        scheduledBlocks,
      );

      if (block != null &&
          !block.endTime.isAfter(task.deadline!)) {
        safeTasks++;
      }
    }

    return ((safeTasks / tasksWithDeadlines.length) * 100)
        .round()
        .clamp(0, 100);
  }

  int _calculateConflictScore(
    List<TimeBlock> scheduledBlocks,
  ) {
    if (scheduledBlocks.length < 2) {
      return 100;
    }

    var conflicts = 0;

    for (var i = 0; i < scheduledBlocks.length; i++) {
      for (var j = i + 1; j < scheduledBlocks.length; j++) {
        if (scheduledBlocks[i].overlaps(scheduledBlocks[j])) {
          conflicts++;
        }
      }
    }

    if (conflicts == 0) {
      return 100;
    }

    final score = 100 - (conflicts * 25);

    return score.clamp(0, 100);
  }

  int _calculateWorkloadBalance(
    List<TimeBlock> scheduledBlocks,
    List<Task> tasks,
  ) {
    if (scheduledBlocks.length < 2) {
      return 100;
    }

    final taskById = {
      for (final task in tasks) task.id: task,
    };

    final sortedBlocks = [...scheduledBlocks]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    var longTaskSequences = 0;

    for (var i = 1; i < sortedBlocks.length; i++) {
      final previousTask = taskById[sortedBlocks[i - 1].taskId];
      final currentTask = taskById[sortedBlocks[i].taskId];

      if (previousTask == null || currentTask == null) {
        continue;
      }

      if (previousTask.estimatedMinutes >= 90 &&
          currentTask.estimatedMinutes >= 90) {
        longTaskSequences++;
      }
    }

    if (longTaskSequences == 0) {
      return 100;
    }

    final score = 100 - (longTaskSequences * 20);

    return score.clamp(0, 100);
  }

  int _calculateTimeUtilization(
    List<TimeBlock> scheduledBlocks,
    DateTime availableStart,
    DateTime availableEnd,
  ) {
    final availableMinutes =
        availableEnd.difference(availableStart).inMinutes;

    if (availableMinutes <= 0) {
      return 0;
    }

    final scheduledMinutes = scheduledBlocks.fold<int>(
      0,
      (total, block) => total + block.duration.inMinutes,
    );

    return ((scheduledMinutes / availableMinutes) * 100)
        .round()
        .clamp(0, 100);
  }

  int _calculateOverallScore({
    required int taskCoverage,
    required int deadlineSafety,
    required int conflictScore,
    required int workloadBalance,
    required int timeUtilization,
  }) {
    final score =
        (taskCoverage * 30) +
        (deadlineSafety * 30) +
        (conflictScore * 20) +
        (workloadBalance * 10) +
        (timeUtilization * 10);

    return (score / 100).round().clamp(0, 100);
  }

  TimeBlock? _findBlockForTask(
    String taskId,
    List<TimeBlock> scheduledBlocks,
  ) {
    for (final block in scheduledBlocks) {
      if (block.taskId == taskId) {
        return block;
      }
    }

    return null;
  }
}