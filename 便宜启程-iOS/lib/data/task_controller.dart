import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/notifications.dart';
import 'models.dart';
import 'repository.dart';
import 'settings_controller.dart';

class TaskController extends ChangeNotifier {
  TaskController(this.settings) {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      final next = dateOnly(DateTime.now());
      if (!isSameDay(next, _today)) {
        load();
      }
    });
  }

  final SettingsController settings;
  final AppRepository _repo = AppRepository.instance;
  Timer? _timer;

  List<Task> allTasks = [];
  List<Completion> completions = [];
  List<Task> todayTasks = [];
  Set<int> doneIds = {};
  DateTime _today = dateOnly(DateTime.now());
  Progress todayProgress = Progress.zero;
  bool loading = false;

  DateTime get today => _today;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    allTasks = await _repo.loadAllTasks();
    completions = await _repo.loadCompletions();
    _recompute();
    loading = false;
    notifyListeners();
    await scheduleNotifications();
  }

  void _recompute() {
    _today = dateOnly(DateTime.now());
    todayTasks = tasksOn(allTasks, _today);
    doneIds = completions
        .where((completion) => isSameDay(completion.date, _today))
        .map((completion) => completion.taskId)
        .toSet();
    todayProgress = Progress(todayTasks.length, todayTasks.where((task) => doneIds.contains(task.id)).length);
  }

  Future<void> scheduleNotifications() async {
    await AppNotifications.instance.scheduleAll(allTasks, completions, settings.settings);
  }

  Future<void> toggle(Task task) async {
    final done = doneIds.contains(task.id);
    await _repo.setCompletion(task.id, _today, !done);
    await load();
  }

  Future<void> save(Task task) async {
    if (task.id == 0) {
      await _repo.insertTask(task);
    } else {
      await _repo.updateTask(task);
    }
    await load();
  }

  Future<void> delete(Task task) async {
    await _repo.softDeleteTask(task.id, DateTime.now());
    await load();
  }

  Future<void> clearAllTasks() async {
    await _repo.clearTasks();
    await load();
  }

  Future<void> clearCompleted() async {
    await _repo.clearCompletions();
    await load();
  }

  Progress get weekProgress => progressWeek(allTasks, completions, _today);
  Progress get monthProgress => progressMonth(allTasks, completions, _today);
  CheckinSummary get checkins => computeCheckins(allTasks, completions, _today);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
