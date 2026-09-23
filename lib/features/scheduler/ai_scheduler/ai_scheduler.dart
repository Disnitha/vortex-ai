import '../../../models/task.dart';

class AiScheduler {
  const AiScheduler();

  List<Task> prioritizeTasks(List<Task> tasks) {
    final pendingTasks = tasks.where((task) {
      return task.status == TaskStatus.pending ||
          task.status == TaskStatus.inProgress;
    }).toList();

    pendingTasks.sort((a, b) {
      // Tasks with deadlines always come before tasks
      // without deadlines.
      if (a.deadline != null && b.deadline == null) {
        return -1;
      }

      if (a.deadline == null && b.deadline != null) {
        return 1;
      }

      final aScore = _calculateTaskScore(a);
      final bScore = _calculateTaskScore(b);

      final scoreComparison = bScore.compareTo(aScore);

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      // Earlier deadlines come first when scores are equal.
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }

      return b.estimatedMinutes.compareTo(
        a.estimatedMinutes,
      );
    });

    return pendingTasks;
  }

  int _calculateTaskScore(Task task) {
    var score = _priorityScore(task.priority) * 100;

    if (task.deadline != null) {
      final hoursUntilDeadline =
          task.deadline!.difference(DateTime.now()).inHours;

      if (hoursUntilDeadline <= 6) {
        score += 80;
      } else if (hoursUntilDeadline <= 24) {
        score += 50;
      } else if (hoursUntilDeadline <= 48) {
        score += 25;
      }
    }

    if (task.status == TaskStatus.inProgress) {
      score += 10;
    }

    return score;
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
}