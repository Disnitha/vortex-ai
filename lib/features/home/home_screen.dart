import 'package:flutter/material.dart';

import '../../core/services/task_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/task.dart';

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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTextStyles.title,
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