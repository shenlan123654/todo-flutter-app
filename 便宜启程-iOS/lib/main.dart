import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/theme.dart';
import 'data/notes_controller.dart';
import 'data/player_controller.dart';
import 'data/settings_controller.dart';
import 'data/task_controller.dart';
import 'services/audio_handler.dart';
import 'services/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsController.instance;
  await settings.load();
  SettingsControllerAccess.settings = settings.settings;
  settings.addListener(() {
    SettingsControllerAccess.settings = settings.settings;
  });

  await AppNotifications.instance.init();

  final tasks = TaskController(settings);
  await tasks.load();

  final notes = NotesController();
  await notes.load();

  final handler = await AudioService.init(
    builder: () => MusicHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.pianyi.qicheng.flutter.audio',
      androidNotificationChannelName: '便宜启程音乐',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_notification',
    ),
  );
  final player = PlayerController(handler, settings);

  AppNotifications.instance.onActionHandled = () {
    tasks.load();
  };

  runApp(
    QiChengApp(
      settings: settings,
      tasks: tasks,
      notes: notes,
      player: player,
    ),
  );
}

class QiChengApp extends StatelessWidget {
  const QiChengApp({
    super.key,
    required this.settings,
    required this.tasks,
    required this.notes,
    required this.player,
  });

  final SettingsController settings;
  final TaskController tasks;
  final NotesController notes;
  final PlayerController player;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: tasks),
        ChangeNotifierProvider.value(value: notes),
        ChangeNotifierProvider.value(value: player),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settingsController, _) {
          final appSettings = settingsController.settings;
          return MaterialApp(
            title: '便宜启程',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(appSettings.fontColor),
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: TextScaler.linear(appSettings.fontScale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
