import 'package:flutter/material.dart';

import '../../core/services/task_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/task.dart';
import '../tasks/create_task_screen.dart';
import '../tasks/task_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskRepository _repository = TaskRepository.instance;

  List<Task> get _tasks => _repository.tasks;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onTasksChanged);
  }

  @override
  void dispose() {
    _repository.removeListener(_onTasksChanged);
    super.dispose();
  }

  void _onTasksChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vortex AI',
          style: AppTextStyles.title,
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning 👋',
                style: AppTextStyles.headline,
              ),

              const SizedBox(height: AppSpacing.sm),

              const Text(
                'Let AI organize your day.',
                style: AppTextStyles.body,
              ),

              const SizedBox(height: AppSpacing.xl),

              // AI Recommendation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'AI Recommendation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Focus on your most important task next.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              const Text(
                "Today's Tasks",
                style: AppTextStyles.title,
              ),

              const SizedBox(height: AppSpacing.md),

              if (_tasks.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'Your schedule is clear.',
                          style: AppTextStyles.title,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Create a task and Vortex AI will help organize your time.',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._tasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.sm,
                    ),
                    child: _TaskItem(
                      task: task,
                      icon: _categoryIcon(task.category),
                    ),
                  ),
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Study':
        return Icons.school_rounded;
      case 'Work':
        return Icons.work_rounded;
      case 'Personal':
        return Icons.person_rounded;
      case 'Health':
        return Icons.favorite_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }
}

class _TaskItem extends StatelessWidget {
  final Task task;
  final IconData icon;

  const _TaskItem({
    required this.task,
    required this.icon,
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

  void _openTaskDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(
          task: task,
        ),
      ),
    );
  }

  void _handleStatusAction(BuildContext context) {
    final repository = TaskRepository.instance;

    switch (task.status) {
      case TaskStatus.pending:
        repository.startTask(task.id);
        break;

      case TaskStatus.inProgress:
        repository.completeTask(task.id);
        break;

      case TaskStatus.completed:
        repository.reopenTask(task.id);
        break;

      case TaskStatus.missed:
        repository.reopenTask(task.id);
        break;
    }
  }

  String _actionLabel() {
    switch (task.status) {
      case TaskStatus.pending:
        return 'Start';

      case TaskStatus.inProgress:
        return 'Complete';

      case TaskStatus.completed:
        return 'Reopen';

      case TaskStatus.missed:
        return 'Reopen';
    }
  }

  IconData _actionIcon() {
    switch (task.status) {
      case TaskStatus.pending:
        return Icons.play_arrow_rounded;

      case TaskStatus.inProgress:
        return Icons.check_rounded;

      case TaskStatus.completed:
        return Icons.replay_rounded;

      case TaskStatus.missed:
        return Icons.replay_rounded;
    }
  }


  Future<void> _editTask(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(
          task: task,
        ),
      ),
    );
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Task "${task.title}" deleted.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(task.status);
    final isCompleted = task.status == TaskStatus.completed;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openTaskDetails(context),
        onLongPress: () => _deleteTask(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primaryLight,
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: AppTextStyles.title.copyWith(
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${task.category} • ${task.estimatedMinutes} min',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          '${_priorityLabel(task.priority)} priority',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    _statusIcon(task.status),
                    color: statusColor,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(task.status),
                          size: 15,
                          color: statusColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _statusLabel(task.status),
                          style: TextStyle(
                          color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  IconButton(
                    onPressed: () => _editTask(context),
                    tooltip: 'Edit task',
                    icon: const Icon(
                      Icons.edit_rounded,
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  FilledButton.icon(
                    onPressed: () => _handleStatusAction(context),
                    icon: Icon(
                      _actionIcon(),
                      size: 18,
                    ),
                    label: Text(_actionLabel()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}