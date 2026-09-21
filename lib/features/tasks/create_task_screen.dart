import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/task.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  String _category = 'General';
  int _estimatedMinutes = 30;
  DateTime? _deadline;

  final List<String> _categories = [
    'General',
    'Study',
    'Work',
    'Personal',
    'Health',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null || !mounted) return;

    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _createTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title.'),
        ),
      );
      return;
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _priority,
      deadline: _deadline,
      estimatedMinutes: _estimatedMinutes,
      category: _category,
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, task);
  }

  String _formatDeadline(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final displayHour = hour == 0 ? 12 : hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day}/${date.month}/${date.year} • '
        '$displayHour:$minute $period';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Task',
          style: AppTextStyles.title,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Task',
                style: AppTextStyles.headline,
              ),

              const SizedBox(height: AppSpacing.sm),

              const Text(
                'Give Vortex AI the details it needs to organize your task.',
                style: AppTextStyles.body,
              ),

              const SizedBox(height: AppSpacing.xl),

              const Text(
                'Task title',
                style: AppTextStyles.label,
              ),

              const SizedBox(height: AppSpacing.sm),

              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'e.g. Complete Physics revision',
                  prefixIcon: Icon(Icons.task_alt_rounded),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Description',
                style: AppTextStyles.label,
              ),

              const SizedBox(height: AppSpacing.sm),

              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Add more details...',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Priority',
                style: AppTextStyles.label,
              ),

              const SizedBox(height: AppSpacing.sm),

              DropdownButtonFormField<TaskPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.flag_rounded),
                ),
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(_priorityLabel(priority)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _priority = value;
                  });
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Category',
                style: AppTextStyles.label,
              ),

              const SizedBox(height: AppSpacing.sm),

              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _category = value;
                  });
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Estimated duration',
                style: AppTextStyles.label,
              ),

              const SizedBox(height: AppSpacing.sm),

              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: AppColors.primaryLight,
                      ),

                      const SizedBox(width: AppSpacing.md),

                      Expanded(
                        child: Slider(
                          value: _estimatedMinutes.toDouble(),
                          min: 15,
                          max: 240,
                          divisions: 15,
                          label: '$_estimatedMinutes min',
                          onChanged: (value) {
                            setState(() {
                              _estimatedMinutes = value.round();
                            });
                          },
                        ),
                      ),

                      SizedBox(
                        width: 58,
                        child: Text(
                          '$_estimatedMinutes min',
                          style: AppTextStyles.label,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Deadline',
                style: AppTextStyles.label,
              ),

              const SizedBox(height: AppSpacing.sm),

              InkWell(
                onTap: _selectDeadline,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.event_rounded),
                    suffixIcon: Icon(Icons.chevron_right_rounded),
                  ),
                  child: Text(
                    _deadline == null
                        ? 'No deadline'
                        : _formatDeadline(_deadline!),
                    style: _deadline == null
                        ? AppTextStyles.body
                        : AppTextStyles.title,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createTask,
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Create Task'),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}