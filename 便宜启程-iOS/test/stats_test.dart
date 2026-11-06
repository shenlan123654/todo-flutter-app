import 'package:flutter_test/flutter_test.dart';
import 'package:qicheng_flutter/data/models.dart';

void main() {
  group('DayPlan', () {
    test('daily task exists between creation and deletion', () {
      final task = Task(
        id: 1,
        title: '阅读',
        createdAt: DateTime(2026, 11, 3),
        deletedAt: DateTime(2026, 11, 5),
      );
      expect(existsOn(task, DateTime(2026, 11, 2)), isFalse);
      expect(existsOn(task, DateTime(2026, 11, 3)), isTrue);
      expect(existsOn(task, DateTime(2026, 11, 4)), isTrue);
      expect(existsOn(task, DateTime(2026, 11, 5)), isFalse);
    });

    test('once task only exists on its date', () {
      final task = Task(
        id: 2,
        title: '交电费',
        repeatType: RepeatType.once,
        onceDate: DateTime(2026, 11, 8),
        createdAt: DateTime(2026, 11, 1),
      );
      expect(existsOn(task, DateTime(2026, 11, 7)), isFalse);
      expect(existsOn(task, DateTime(2026, 11, 8)), isTrue);
      expect(existsOn(task, DateTime(2026, 11, 9)), isFalse);
    });
  });

  group('Stats', () {
    final tasks = [
      Task(id: 1, title: 'A', createdAt: DateTime(2026, 11, 3), deletedAt: DateTime(2026, 11, 5)),
      Task(id: 2, title: 'B', createdAt: DateTime(2026, 11, 1)),
      Task(
        id: 3,
        title: 'C',
        repeatType: RepeatType.once,
        onceDate: DateTime(2026, 11, 4),
        createdAt: DateTime(2026, 11, 1),
      ),
    ];
    final completions = [
      Completion(taskId: 1, date: DateTime(2026, 11, 3)),
      Completion(taskId: 1, date: DateTime(2026, 11, 4)),
      Completion(taskId: 2, date: DateTime(2026, 11, 3)),
      Completion(taskId: 3, date: DateTime(2026, 11, 4)),
      Completion(taskId: 2, date: DateTime(2026, 11, 5)),
    ];
    final today = DateTime(2026, 11, 5);

    test('today counts only today tasks', () {
      final progress = progressToday(tasks, completions, today);
      expect(progress.total, 1);
      expect(progress.done, 1);
      expect(progress.percent, 100);
    });

    test('week starts on Monday', () {
      final progress = progressWeek(tasks, completions, today);
      expect(progress.total, 7);
      expect(progress.done, 5);
    });

    test('month starts on first day', () {
      final progress = progressMonth(tasks, completions, today);
      expect(progress.total, 8);
      expect(progress.done, 5);
    });
  });

  group('Checkins', () {
    test('only fully completed days count', () {
      final tasks = [
        Task(id: 1, title: 'A', createdAt: DateTime(2026, 11, 3), deletedAt: DateTime(2026, 11, 5)),
        Task(id: 2, title: 'B', createdAt: DateTime(2026, 11, 1)),
        Task(
          id: 3,
          title: 'C',
          repeatType: RepeatType.once,
          onceDate: DateTime(2026, 11, 4),
          createdAt: DateTime(2026, 11, 1),
        ),
      ];
      final completions = [
        Completion(taskId: 1, date: DateTime(2026, 11, 3)),
        Completion(taskId: 1, date: DateTime(2026, 11, 4)),
        Completion(taskId: 2, date: DateTime(2026, 11, 3)),
        Completion(taskId: 3, date: DateTime(2026, 11, 4)),
        Completion(taskId: 2, date: DateTime(2026, 11, 5)),
      ];
      final summary = computeCheckins(tasks, completions, DateTime(2026, 11, 5));
      expect(summary.totalDays, 2);
      expect(summary.streak, 1);
    });

    test('days without tasks are neutral for streak', () {
      final tasks = [
        Task(
          id: 1,
          title: 'A',
          repeatType: RepeatType.once,
          onceDate: DateTime(2026, 11, 1),
          createdAt: DateTime(2026, 11, 1),
        ),
        Task(
          id: 2,
          title: 'B',
          repeatType: RepeatType.once,
          onceDate: DateTime(2026, 11, 3),
          createdAt: DateTime(2026, 11, 3),
        ),
      ];
      final completions = [
        Completion(taskId: 1, date: DateTime(2026, 11, 1)),
        Completion(taskId: 2, date: DateTime(2026, 11, 3)),
      ];
      final summary = computeCheckins(tasks, completions, DateTime(2026, 11, 3));
      expect(summary.totalDays, 2);
      expect(summary.streak, 2);
    });
  });

  group('Reminder occurrences', () {
    test('daily task schedules future days and skips completed today', () {
      final task = Task(
        id: 1,
        title: '喝水',
        reminderEnabled: true,
        reminderTime: '09:00',
        createdAt: DateTime(2026, 11, 1),
      );
      final now = DateTime(2026, 11, 5, 8, 0);
      final occurrences = reminderOccurrences(task, now, {1}, 3);
      expect(occurrences.map((item) => item.date), [
        DateTime(2026, 11, 6, 9, 0),
        DateTime(2026, 11, 7, 9, 0),
        DateTime(2026, 11, 8, 9, 0),
      ]);
    });
  });
}
