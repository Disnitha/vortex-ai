import '../../../models/task.dart';
import 'time_block.dart';

class TimeBlockingEngine {
  TimeBlock? findAvailableSlot({
    required Task task,
    required DateTime availableStart,
    required DateTime availableEnd,
    required List<TimeBlock> existingBlocks,
  }) {
    final duration = Duration(
      minutes: task.estimatedMinutes,
    );

    DateTime candidateStart = availableStart;

    while (candidateStart.add(duration).isBefore(availableEnd) ||
        candidateStart.add(duration).isAtSameMomentAs(availableEnd)) {
      final candidateEnd = candidateStart.add(duration);

      final candidateBlock = TimeBlock(
        id: '${task.id}_${candidateStart.millisecondsSinceEpoch}',
        taskId: task.id,
        startTime: candidateStart,
        endTime: candidateEnd,
      );

      final hasOverlap = existingBlocks.any(
        (block) => candidateBlock.overlaps(block),
      );

      if (!hasOverlap) {
        return candidateBlock;
      }

      candidateStart = candidateStart.add(
        const Duration(minutes: 15),
      );
    }

    return null;
  }
}