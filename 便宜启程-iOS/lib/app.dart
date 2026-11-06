import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/widgets.dart';
import 'data/settings_controller.dart';
import 'data/task_controller.dart';
import 'screens/customize_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/player_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';
import 'screens/tools_screen.dart';
import 'services/notifications.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;

  static const _items = [
    BottomNavItem('每日清单', Icons.home_rounded),
    BottomNavItem('其它工具', Icons.work_rounded),
    BottomNavItem('我的', Icons.person_rounded),
    BottomNavItem('设置', Icons.settings_rounded),
    BottomNavItem('自定义', Icons.tune_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppNotifications.instance.requestPermissions();
      if (!mounted) return;
      await context.read<TaskController>().scheduleNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TaskController>().load();
      context.read<SettingsController>();
      AppNotifications.instance.onActionHandled = () {
        if (mounted) context.read<TaskController>().load();
      };
    }
  }

  void _openNotes() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotesScreen()),
    );
  }

  void _openPlayer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TodayScreen(),
      ToolsScreen(onOpenPlayer: _openPlayer, onOpenNotes: _openNotes),
      const ProfileScreen(),
      const SettingsScreen(),
      const CustomizeScreen(),
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        home: _index == 0,
        child: SafeArea(
          bottom: false,
          child: IndexedStack(index: _index, children: pages),
        ),
      ),
      bottomNavigationBar: QichengBottomBar(
        index: _index,
        onChanged: (value) => setState(() => _index = value),
        items: _items,
      ),
    );
  }
}
