import '../../../models/task.dart';

class AiScheduler {
  const AiScheduler();

  List<Task> prioritizeTasks(List<Task> tasks) {
    final pendingTasks = tasks.where((task) {
      return task.status == TaskStatus.pending ||
          task.status == TaskStatus.inProgress;
    }).toList();

    pendingTasks.sort((a, b) {
      final priorityComparison =
          _priorityScore(b.priority).compareTo(
        _priorityScore(a.priority),
      );

      if (priorityComparison != 0) {
        return priorityComparison;
      }

      final deadlineComparison = _compareDeadlines(
        a.deadline,
        b.deadline,
      );

      if (deadlineComparison != 0) {
        return deadlineComparison;
      }

      return b.estimatedMinutes.compareTo(
        a.estimatedMinutes,
      );
    });

    return pendingTasks;
  }

  int _priorityScore(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 1;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.high:
        return 3;
      case TaskPriority.urgent:
        return 4;
    }
  }

  int _compareDeadlines(
    DateTime? first,
    DateTime? second,
  ) {
    if (first == null && second == null) {
      return 0;
    }

    if (first == null) {
      return 1;
    }

    if (second == null) {
      return -1;
    }

    return first.compareTo(second);
  }
}