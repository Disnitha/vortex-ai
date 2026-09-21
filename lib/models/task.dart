enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
  missed,
}

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? deadline;
  final int estimatedMinutes;
  final String category;
  final bool isRecurring;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.deadline,
    this.estimatedMinutes = 30,
    this.category = 'General',
    this.isRecurring = false,
    required this.createdAt,
  });
}