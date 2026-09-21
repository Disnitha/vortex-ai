import 'package:flutter/material.dart';

import '../../core/services/task_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/task.dart';
import 'create_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskRepository _repository = TaskRepository.instance;

  List<Task> get _tasks => _repository.tasks;

  Future<void> _openCreateTask() async {
    final task = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateTaskScreen(),
      ),
    );

    if (task == null || !mounted) return;

    _repository.addTask(task);

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Task "${task.title}" created successfully.',
        ),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tasks',
          style: AppTextStyles.title,
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTask,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Text(
              'Your Tasks',
              style: AppTextStyles.headline,
            ),

            const SizedBox(height: AppSpacing.sm),

            const Text(
              'Manage your tasks and let Vortex AI organize them.',
              style: AppTextStyles.body,
            ),

            const SizedBox(height: AppSpacing.xl),

            if (_tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxxl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_alt_rounded,
                        size: 56,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'No tasks yet.',
                        style: AppTextStyles.title,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Create your first task to get started.',
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
                    bottom: AppSpacing.md,
                  ),
                  child: _TaskCard(
                    title: task.title,
                    category: task.category,
                    priority: _priorityLabel(task.priority),
                    duration: '${task.estimatedMinutes} min',
                    icon: _categoryIcon(task.category),
                  ),
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String category;
  final String priority;
  final String duration;
  final IconData icon;

  const _TaskCard({
    required this.title,
    required this.category,
    required this.priority,
    required this.duration,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
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
                size: 24,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.title,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '$category • $duration',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      priority,
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}