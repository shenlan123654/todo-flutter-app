import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/theme.dart';
import '../data/models.dart';
import '../data/repository.dart';

class AppNotifications {
  AppNotifications._();
  static final AppNotifications instance = AppNotifications._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _canExact = true;
  VoidCallback? onActionHandled;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));

    const android = AndroidInitializationSettings('@drawable/ic_notification');
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'qicheng_task',
          actions: [
            DarwinNotificationAction.plain('complete', '完成'),
            DarwinNotificationAction.plain('snooze', '稍后10分钟'),
          ],
        ),
      ],
    );
    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
    _initialized = true;
    _canExact = await _checkExact();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await init();
  }

  Future<bool> _checkExact() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final value = await android?.canScheduleExactNotifications();
    return value ?? true;
  }

  Future<bool> requestPermissions() async {
    await _ensureInitialized();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission() ?? true;
    final iosGranted = await ios?.requestPermissions(alert: true, sound: true, badge: true) ?? true;
    _canExact = await _checkExact();
    return androidGranted && iosGranted;
  }

  Future<bool> requestExactPermission() async {
    await _ensureInitialized();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestExactAlarmsPermission();
    _canExact = await _checkExact();
    return granted ?? _canExact;
  }

  Future<bool> get canExact async {
    await _ensureInitialized();
    _canExact = await _checkExact();
    return _canExact;
  }

  Future<void> scheduleAll(
    List<Task> tasks,
    List<Completion> completions,
    AppSettings settings,
  ) async {
    await _ensureInitialized();
    await _plugin.cancelAll();
    if (!settings.reminderMasterOn) return;

    final active = tasks.where((task) => task.deletedAt == null).toList();
    if (active.isEmpty) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final doneToday = completions
        .where((completion) => isSameDay(completion.date, today))
        .map((completion) => completion.taskId)
        .toSet();
    final horizon = active.length <= 8 ? 7 : (60 ~/ active.length).clamp(1, 7);

    for (final task in active) {
      for (final occurrence in reminderOccurrences(task, now, doneToday, horizon)) {
        final offset = occurrence.date.difference(today).inDays;
        await _schedule(
          id: task.id * 1000 + offset,
          at: occurrence.date,
          title: task.title,
          body: _bodyFor(task),
          payload: {
            'taskId': task.id,
            'title': task.title,
            'body': _bodyFor(task),
          },
          settings: settings,
        );
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
    required AppSettings settings,
  }) async {
    if (!at.isAfter(DateTime.now())) return;
    final channelId = 'qicheng_reminder_${settings.vibrationOn ? 1 : 0}';
    final android = AndroidNotificationDetails(
      channelId,
      '任务提醒',
      channelDescription: '便宜启程的每日清单提醒',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: settings.vibrationOn,
      vibrationPattern: settings.vibrationOn ? Int64List.fromList([0, 260, 160, 260]) : null,
      category: AndroidNotificationCategory.reminder,
      actions: const [
        AndroidNotificationAction('complete', '完成', showsUserInterface: false, cancelNotification: true),
        AndroidNotificationAction('snooze', '稍后10分钟', showsUserInterface: false, cancelNotification: true),
      ],
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      categoryIdentifier: 'qicheng_task',
    );
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: NotificationDetails(android: android, iOS: ios),
      androidScheduleMode: _canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: jsonEncode(payload),
    );
  }

  Future<void> showTest(AppSettings settings) async {
    await _ensureInitialized();
    final android = AndroidNotificationDetails(
      'qicheng_reminder_test',
      '测试通知',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: settings.vibrationOn,
    );
    const ios = DarwinNotificationDetails(presentAlert: true, presentSound: true);
    await _plugin.show(
      id: 999001,
      title: '测试提醒 · 便宜启程',
      body: '看到这条通知，说明提醒通道正常',
      notificationDetails: NotificationDetails(android: android, iOS: ios),
      payload: '{"test":true}',
    );
  }

  Future<void> scheduleSnooze({
    required int taskId,
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    await _schedule(
      id: 900000 + taskId,
      at: DateTime.now().add(const Duration(minutes: 10)),
      title: title,
      body: body,
      payload: {'taskId': taskId, 'title': title, 'body': body},
      settings: SettingsControllerAccess.settings,
    );
  }

  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }

  Future<void> _onForegroundResponse(NotificationResponse response) async {
    await _handleResponse(response);
    onActionHandled?.call();
  }

  Future<void> handleBackground(NotificationResponse response) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await init();
    await _handleResponse(response);
  }

  Future<void> _handleResponse(NotificationResponse response) async {
    final action = response.actionId;
    if (action != 'complete' && action != 'snooze') return;
    Map<String, dynamic> payload = {};
    try {
      final decoded = jsonDecode(response.payload ?? '{}');
      if (decoded is Map<String, dynamic>) payload = decoded;
    } catch (_) {}
    final taskId = (payload['taskId'] as num?)?.toInt();
    if (taskId == null) return;
    if (action == 'complete') {
      await AppRepository.instance.setCompletion(taskId, DateTime.now(), true);
    } else {
      await scheduleSnooze(
        taskId: taskId,
        title: payload['title'] as String? ?? '任务提醒',
        body: payload['body'] as String? ?? '该做事了',
      );
    }
  }

  String _bodyFor(Task task) {
    final time = timeLabel(DateTime(2000, 1, 1, task.reminderHour, task.reminderMinute));
    final String when;
    if (task.repeatType == RepeatType.daily) {
      when = '每日任务 · $time';
    } else if (task.onceDate != null) {
      when = '${task.onceDate!.month}月${task.onceDate!.day}日 · $time';
    } else {
      when = time;
    }
    return task.note.isEmpty ? when : '${task.note} · $when';
  }
}

// Filled in main with the current settings to avoid passing them into the
// background notification isolate.
class SettingsControllerAccess {
  static AppSettings settings = const AppSettings();
}

@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  AppNotifications.instance.handleBackground(response);
}
