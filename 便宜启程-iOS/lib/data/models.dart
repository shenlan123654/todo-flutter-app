enum RepeatType { daily, once }

enum TaskIconType { emoji, png }

enum CheckboxStyle { square, rounded, dot, outline }

enum PlayerLoopMode { off, all, one, selected }

class Task {
  const Task({
    this.id = 0,
    required this.title,
    this.note = '',
    this.iconType = TaskIconType.emoji,
    this.iconValue = '📖',
    this.repeatType = RepeatType.daily,
    this.onceDate,
    this.reminderEnabled = false,
    this.reminderTime = '09:00',
    required this.createdAt,
    this.deletedAt,
    this.sortOrder = 0,
  });

  final int id;
  final String title;
  final String note;
  final TaskIconType iconType;
  final String iconValue;
  final RepeatType repeatType;
  final DateTime? onceDate;
  final bool reminderEnabled;
  final String reminderTime;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final int sortOrder;

  int get reminderHour => int.tryParse(reminderTime.split(':').first) ?? 9;
  int get reminderMinute {
    final parts = reminderTime.split(':');
    return parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  }

  Task copyWith({
    int? id,
    String? title,
    String? note,
    TaskIconType? iconType,
    String? iconValue,
    RepeatType? repeatType,
    DateTime? onceDate,
    bool clearOnceDate = false,
    bool? reminderEnabled,
    String? reminderTime,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? sortOrder,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      iconType: iconType ?? this.iconType,
      iconValue: iconValue ?? this.iconValue,
      repeatType: repeatType ?? this.repeatType,
      onceDate: clearOnceDate ? null : (onceDate ?? this.onceDate),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class Completion {
  const Completion({required this.taskId, required this.date});
  final int taskId;
  final DateTime date;
}

class Note {
  const Note({
    this.id = 0,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
  });
  final int id;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> images;
}

class Song {
  const Song({
    this.id = 0,
    required this.title,
    this.artist = '',
    required this.filePath,
    this.durationMs = 0,
    required this.addedAt,
  });
  final int id;
  final String title;
  final String artist;
  final String filePath;
  final int durationMs;
  final DateTime addedAt;
}

class AppSettings {
  const AppSettings({
    this.reminderMasterOn = true,
    this.vibrationOn = true,
    this.defaultReminderTime = '09:00',
    this.fontColor = 0xFFEAF6FF,
    this.fontScale = 1.0,
    this.checkboxStyle = CheckboxStyle.square,
    this.homeBackground,
    this.otherBackground,
    this.backgroundDim = 0.42,
    this.logoPath,
    this.notificationSound = 'default',
    this.playerSpeed = 1.0,
    this.playerLoopMode = PlayerLoopMode.off,
    this.selectedSongIds = const <int>{},
  });

  final bool reminderMasterOn;
  final bool vibrationOn;
  final String defaultReminderTime;
  final int fontColor;
  final double fontScale;
  final CheckboxStyle checkboxStyle;
  final String? homeBackground;
  final String? otherBackground;
  final double backgroundDim;
  final String? logoPath;
  final String notificationSound;
  final double playerSpeed;
  final PlayerLoopMode playerLoopMode;
  final Set<int> selectedSongIds;

  AppSettings copyWith({
    bool? reminderMasterOn,
    bool? vibrationOn,
    String? defaultReminderTime,
    int? fontColor,
    double? fontScale,
    CheckboxStyle? checkboxStyle,
    String? homeBackground,
    bool clearHomeBackground = false,
    String? otherBackground,
    bool clearOtherBackground = false,
    double? backgroundDim,
    String? logoPath,
    bool clearLogo = false,
    String? notificationSound,
    double? playerSpeed,
    PlayerLoopMode? playerLoopMode,
    Set<int>? selectedSongIds,
  }) {
    return AppSettings(
      reminderMasterOn: reminderMasterOn ?? this.reminderMasterOn,
      vibrationOn: vibrationOn ?? this.vibrationOn,
      defaultReminderTime: defaultReminderTime ?? this.defaultReminderTime,
      fontColor: fontColor ?? this.fontColor,
      fontScale: fontScale ?? this.fontScale,
      checkboxStyle: checkboxStyle ?? this.checkboxStyle,
      homeBackground: clearHomeBackground ? null : (homeBackground ?? this.homeBackground),
      otherBackground: clearOtherBackground ? null : (otherBackground ?? this.otherBackground),
      backgroundDim: backgroundDim ?? this.backgroundDim,
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
      notificationSound: notificationSound ?? this.notificationSound,
      playerSpeed: playerSpeed ?? this.playerSpeed,
      playerLoopMode: playerLoopMode ?? this.playerLoopMode,
      selectedSongIds: selectedSongIds ?? this.selectedSongIds,
    );
  }
}

class Progress {
  const Progress(this.total, this.done);
  final int total;
  final int done;

  double get rate => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
  int get percent => (rate * 100).floor();
  bool get isFull => total > 0 && done >= total;

  static const zero = Progress(0, 0);
}

class CheckinSummary {
  const CheckinSummary(this.totalDays, this.streak);
  final int totalDays;
  final int streak;
  static const empty = CheckinSummary(0, 0);
}

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool existsOn(Task task, DateTime day) {
  final date = dateOnly(day);
  if (dateOnly(task.createdAt).isAfter(date)) return false;
  final deleted = task.deletedAt;
  if (deleted != null && !dateOnly(deleted).isAfter(date)) return false;
  return switch (task.repeatType) {
    RepeatType.daily => true,
    RepeatType.once => task.onceDate != null && isSameDay(task.onceDate!, date),
  };
}

List<Task> tasksOn(List<Task> tasks, DateTime day) =>
    tasks.where((task) => existsOn(task, day)).toList();

Progress progressBetween(
  List<Task> tasks,
  List<Completion> completions,
  DateTime from,
  DateTime to,
) {
  var start = dateOnly(from);
  final end = dateOnly(to);
  if (start.isAfter(end)) return Progress.zero;
  var total = 0;
  var done = 0;
  while (!start.isAfter(end)) {
    final dayTasks = tasksOn(tasks, start);
    final doneIds = completions
        .where((completion) => isSameDay(completion.date, start))
        .map((completion) => completion.taskId)
        .toSet();
    total += dayTasks.length;
    done += dayTasks.where((task) => doneIds.contains(task.id)).length;
    start = start.add(const Duration(days: 1));
  }
  return Progress(total, done);
}

Progress progressToday(List<Task> tasks, List<Completion> completions, DateTime today) =>
    progressBetween(tasks, completions, today, today);

Progress progressWeek(List<Task> tasks, List<Completion> completions, DateTime today) {
  final monday = dateOnly(today).subtract(Duration(days: today.weekday - 1));
  return progressBetween(tasks, completions, monday, today);
}

Progress progressMonth(List<Task> tasks, List<Completion> completions, DateTime today) {
  final first = DateTime(today.year, today.month, 1);
  return progressBetween(tasks, completions, first, today);
}

CheckinSummary computeCheckins(
  List<Task> tasks,
  List<Completion> completions,
  DateTime today,
) {
  if (tasks.isEmpty) return CheckinSummary.empty;
  final earliest = tasks
      .map((task) => dateOnly(task.createdAt))
      .reduce((a, b) => a.isBefore(b) ? a : b);
  if (earliest.isAfter(today)) return CheckinSummary.empty;

  Progress progressOn(DateTime day) {
    final dayTasks = tasksOn(tasks, day);
    final doneIds = completions
        .where((completion) => isSameDay(completion.date, day))
        .map((completion) => completion.taskId)
        .toSet();
    return Progress(dayTasks.length, dayTasks.where((t) => doneIds.contains(t.id)).length);
  }

  var totalDays = 0;
  var cursor = earliest;
  while (!cursor.isAfter(today)) {
    final p = progressOn(cursor);
    if (p.isFull) totalDays++;
    cursor = cursor.add(const Duration(days: 1));
  }

  var streakCursor = dateOnly(today);
  final todayProgress = progressOn(streakCursor);
  if (todayProgress.total > 0 && !todayProgress.isFull) {
    streakCursor = streakCursor.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (!streakCursor.isBefore(earliest)) {
    final p = progressOn(streakCursor);
    if (p.total == 0) {
      streakCursor = streakCursor.subtract(const Duration(days: 1));
      continue;
    }
    if (p.isFull) {
      streak++;
      streakCursor = streakCursor.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return CheckinSummary(totalDays, streak);
}

class ReminderOccurrence {
  const ReminderOccurrence(this.date, this.taskId);
  final DateTime date;
  final int taskId;
}

List<ReminderOccurrence> reminderOccurrences(
  Task task,
  DateTime now,
  Set<int> completedTaskIds,
  int days,
) {
  final result = <ReminderOccurrence>[];
  if (!task.reminderEnabled || task.deletedAt != null) return result;
  final today = dateOnly(now);
  for (var offset = 0; offset <= days; offset++) {
    final day = today.add(Duration(days: offset));
    if (!existsOn(task, day)) continue;
    final at = DateTime(day.year, day.month, day.day, task.reminderHour, task.reminderMinute);
    if (!at.isAfter(now)) continue;
    if (offset == 0 && completedTaskIds.contains(task.id)) continue;
    result.add(ReminderOccurrence(at, task.id));
  }
  return result;
}
