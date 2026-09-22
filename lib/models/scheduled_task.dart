class ScheduledTask {
  final String id;
  final String taskId;
  final DateTime startTime;
  final DateTime endTime;

  const ScheduledTask({
    required this.id,
    required this.taskId,
    required this.startTime,
    required this.endTime,
  });

  Duration get duration {
    return endTime.difference(startTime);
  }

  ScheduledTask copyWith({
    String? id,
    String? taskId,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return ScheduledTask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }

  factory ScheduledTask.fromMap(Map<String, dynamic> map) {
    return ScheduledTask(
      id: map['id'] as String,
      taskId: map['taskId'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
    );
  }
}