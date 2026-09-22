import '../../../models/scheduled_task.dart';

class TimeBlock {
  final String id;
  final String taskId;
  final DateTime startTime;
  final DateTime endTime;

  const TimeBlock({
    required this.id,
    required this.taskId,
    required this.startTime,
    required this.endTime,
  });

  Duration get duration {
    return endTime.difference(startTime);
  }

  bool overlaps(TimeBlock other) {
    return startTime.isBefore(other.endTime) &&
        endTime.isAfter(other.startTime);
  }

  ScheduledTask toScheduledTask() {
    return ScheduledTask(
      id: id,
      taskId: taskId,
      startTime: startTime,
      endTime: endTime,
    );
  }
}