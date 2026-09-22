import 'package:flutter/material.dart';

import '../../core/services/task_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/task.dart';
import 'create_task_screen.dart';

class TaskDetailsScreen extends StatelessWidget {
  final Task task;

  const TaskDetailsScreen({
    super.key,
    required this.task,
  });

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.missed:
        return 'Missed';
    }
  }

  IconData _statusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.schedule_rounded;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline_rounded;
      case TaskStatus.completed:
        return Icons.check_circle_rounded;
      case TaskStatus.missed:
        return Icons.warning_amber_rounded;
    }
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppColors.primaryLight;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.missed:
        return Colors.red;
    }
  }

  String _formatDeadline(DateTime? deadline) {
    if (deadline == null) {
      return 'No deadline';
    }

    final hour = deadline.hour > 12 ? deadline.hour - 12 : deadline.hour;
    final displayHour = hour == 0 ? 12 : hour;
    final minute = deadline.minute.toString().padLeft(2, '0');
    final period = deadline.hour >= 12 ? 'PM' : 'AM';

    return '${deadline.day}/${deadline.month}/${deadline.year} • '
        '$displayHour:$minute $period';
  }

  Future<void> _editTask(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(task: task),
      ),
    );

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteTask(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task?'),
          content: Text(
            'Are you sure you want to delete "${task.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await TaskRepository.instance.removeTask(task.id);

    if (!context.mounted) return;

    Navigator.pop(context);
  }

  void _handleStatusAction() {
    final repository = TaskRepository.instance;

    switch (task.status) {
      case TaskStatus.pending:
        repository.startTask(task.id);
        break;
      case TaskStatus.inProgress:
        repository.completeTask(task.id);
        break;
      case TaskStatus.completed:
      case TaskStatus.missed:
        repository.reopenTask(task.id);
        break;
    }
  }

  String _actionLabel() {
    switch (task.status) {
      case TaskStatus.pending:
        return 'Start Task';
      case TaskStatus.inProgress:
        return 'Complete Task';
      case TaskStatus.completed:
      case TaskStatus.missed:
        return 'Reopen Task';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(task.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Task Details',
          style: AppTextStyles.title,
        ),
        actions: [
          IconButton(
            onPressed: () => _editTask(context),
            tooltip: 'Edit task',
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: () => _deleteTask(context),
            tooltip: 'Delete task',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: AppTextStyles.headline,
              ),

              const SizedBox(height: AppSpacing.sm),

              if (task.description != null &&
                  task.description!.isNotEmpty)
                Text(
                  task.description!,
                  style: AppTextStyles.body,
                ),

              const SizedBox(height: AppSpacing.xl),

              _InfoCard(
                icon: Icons.flag_rounded,
                title: 'Priority',
                value: _priorityLabel(task.priority),
              ),

              const SizedBox(height: AppSpacing.md),

              _InfoCard(
                icon: Icons.category_rounded,
                title: 'Category',
                value: task.category,
              ),

              const SizedBox(height: AppSpacing.md),

              _InfoCard(
                icon: Icons.schedule_rounded,
                title: 'Estimated Duration',
                value: '${task.estimatedMinutes} minutes',
              ),

              const SizedBox(height: AppSpacing.md),

              _InfoCard(
                icon: Icons.event_rounded,
                title: 'Deadline',
                value: _formatDeadline(task.deadline),
              ),

              const SizedBox(height: AppSpacing.md),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        _statusIcon(task.status),
                        color: statusColor,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Status',
                          style: AppTextStyles.label,
                        ),
                      ),
                      Text(
                        _statusLabel(task.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleStatusAction,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(_actionLabel()),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _editTask(context),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryLight,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.label,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.title,
            ),
          ],
        ),
      ),
    );
  }
}