import 'package:flutter/material.dart';

import '../../core/services/schedule_repository.dart';
import '../../core/services/task_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/scheduled_task.dart';
import '../../models/task.dart';
import '../scheduler/ai_scheduler/schedule_generation_service.dart';
import '../scheduler/ai_scheduler/daily_plan_generation_service.dart';
import '../scheduler/optimization/schedule_quality_analyzer.dart';
import '../scheduler/time_blocking/time_block.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  final ScheduleRepository _scheduleRepository =
      ScheduleRepository.instance;

  final TaskRepository _taskRepository =
      TaskRepository.instance;

  final ScheduleGenerationService _scheduleGenerationService =
      ScheduleGenerationService();

  DateTime _selectedDate = DateTime.now();
  ScheduleQualityResult? _scheduleQuality;

  Future<void> _planMyDay() async {
    final taskRepository = TaskRepository.instance;

    final tasks = taskRepository.tasks.where((task) {
      return task.status == TaskStatus.pending ||
          task.status == TaskStatus.inProgress;
    }).toList();

    if (tasks.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending tasks to plan.'),
        ),
      );

      return;
    }

    final now = DateTime.now();

    final availableStart = now.add(
      const Duration(minutes: 10),
    );

    final availableEnd = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
    );

    if (!availableStart.isBefore(availableEnd)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No planning time remaining today.'),
        ),
      );

      return;
    }

    final plan = await DailyPlanGenerationService()
        .generateAndSaveDailyPlan(
      tasks: tasks,
      availableStart: availableStart,
      availableEnd: availableEnd,
    );

    if (!mounted) return;

    if (plan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available time slots found.'),
        ),
      );

      return;
    }

    final scheduledTasks =
        _scheduleRepository.getScheduledTasksForDate(
      now,
    );

    final scheduledBlocks = scheduledTasks.map(
      (scheduledTask) {
        return TimeBlock(
          id: scheduledTask.id,
          taskId: scheduledTask.taskId,
          startTime: scheduledTask.startTime,
          endTime: scheduledTask.endTime,
        );
      },
    ).toList();

    final quality = ScheduleQualityAnalyzer().analyze(
      tasks: tasks,
      scheduledBlocks: scheduledBlocks,
      availableStart: availableStart,
      availableEnd: availableEnd,
    );

    setState(() {
      _scheduleQuality = quality;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Planned ${plan.length} task${plan.length == 1 ? '' : 's'} for today.',
        ),
      ),
    );
  } 

  Future<void> _clearSchedule() async {
    final hasSchedule = _scheduledTasks.isNotEmpty;

    if (!hasSchedule) {
      _showMessage('No scheduled tasks to clear.');
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Schedule?'),
          content: const Text(
            'This will remove the scheduled time blocks for this day. '
            'Your tasks will not be deleted.',
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
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) {
      return;
    }

    await _scheduleRepository.removeScheduledTasksForDate(
      _selectedDate,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _scheduleQuality = null;
    });

    _showMessage('Schedule cleared.');
  }

  Future<void> _generateSchedule() async {
  final tasks = _taskRepository.tasks.where((task) {
    return task.status == TaskStatus.pending ||
        task.status == TaskStatus.inProgress;
  }).toList();

  if (tasks.isEmpty) {
    _showMessage('No pending tasks to schedule.');
    return;
  }

  final dayStart = DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    7,
    0,
  );

  final dayEnd = DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    23,
    59,
  );

  final generationResult =
      await _scheduleGenerationService.generateScheduleWithQuality(
    tasks: tasks,
    availableStart: dayStart,
    availableEnd: dayEnd,
  );

  final generatedBlocks = generationResult.blocks;

  if (mounted) {
    setState(() {
      _scheduleQuality = generationResult.quality;
    });
  }

  if (generatedBlocks.isEmpty) {
    _showMessage('No available time slots found.');
    return;
  }

  _showMessage(
    '${generatedBlocks.length} task(s) scheduled.',
  );
}

  @override
  void initState() {
    super.initState();

    _scheduleRepository.addListener(_onRepositoryChanged);
    _taskRepository.addListener(_onRepositoryChanged);
  }

  @override
  void dispose() {
    _scheduleRepository.removeListener(_onRepositoryChanged);
    _taskRepository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  void _onRepositoryChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  List<ScheduledTask> get _scheduledTasks {
    final tasks = _scheduleRepository.getScheduledTasksForDate(
      _selectedDate,
    );

    tasks.sort(
      (a, b) => a.startTime.compareTo(b.startTime),
    );

    return tasks;
  }

  Task? _findTask(String taskId) {
    for (final task in _taskRepository.tasks) {
      if (task.id == taskId) {
        return task;
      }
    }

    return null;
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _scheduleQuality = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduledTasks = _scheduledTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateSelector(
                selectedDate: _selectedDate,
                onDateSelected: _selectDate,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _clearSchedule,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                      ),
                      label: const Text('Clear'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _planMyDay,
                      icon: const Icon(
                        Icons.auto_awesome,
                        size: 18,
                      ),
                      label: const Text('Plan My Day'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: _generateSchedule,
                      icon: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                      ),
                      label: const Text('Generate'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_scheduleQuality != null) ...[
                _ScheduleQualityCard(
                  quality: _scheduleQuality!,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Expanded(
                child: scheduledTasks.isEmpty
                    ? const _EmptySchedule()
                    : ListView.separated(
                        itemCount: scheduledTasks.length,
                        separatorBuilder: (_, _) {
                          return const SizedBox(
                            height: AppSpacing.sm,
                          );
                        },
                        itemBuilder: (context, index) {
                          final scheduledTask =
                              scheduledTasks[index];

                          return _ScheduleCard(
                            scheduledTask: scheduledTask,
                            task: _findTask(
                              scheduledTask.taskId,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    final dates = List.generate(
      7,
      (index) => DateTime(
        today.year,
        today.month,
        today.day + index,
      ),
    );

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) {
          return const SizedBox(
            width: AppSpacing.sm,
          );
        },
        itemBuilder: (context, index) {
          final date = dates[index];

          final isSelected =
              date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 64,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayLabel(date.weekday),
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return labels[weekday - 1];
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.scheduledTask,
    required this.task,
  });

  final ScheduledTask scheduledTask;
  final Task? task;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(scheduledTask.startTime),
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task?.title ?? 'Unknown task',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task == null
                        ? 'Task no longer exists'
                        : '${task!.category} • '
                            '${_formatDuration(scheduledTask.duration)}',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour % 12 == 0 ? 12 : time.hour % 12;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '$hours h $minutes min';
    }

    if (hours > 0) {
      return '$hours h';
    }

    return '$minutes min';
  }
}

class _ScheduleQualityCard extends StatelessWidget {
  const _ScheduleQualityCard({
    required this.quality,
  });

  final ScheduleQualityResult quality;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Schedule Quality',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${quality.overallScore}/100',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _QualityRow(
              label: 'Task coverage',
              value: quality.taskCoverage,
            ),
            _QualityRow(
              label: 'Deadline safety',
              value: quality.deadlineSafety,
            ),
            _QualityRow(
              label: 'Conflict-free',
              value: quality.conflictScore,
            ),
            _QualityRow(
              label: 'Workload balance',
              value: quality.workloadBalance,
            ),
            _QualityRow(
              label: 'Time utilization',
              value: quality.timeUtilization,
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityRow extends StatelessWidget {
  const _QualityRow({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          Text(
            '$value%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No scheduled tasks for this day.',
      ),
    );
  }
}