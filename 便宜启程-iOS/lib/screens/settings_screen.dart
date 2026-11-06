import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/database.dart';
import '../data/file_store.dart';
import '../data/notes_controller.dart';
import '../data/player_controller.dart';
import '../data/settings_controller.dart';
import '../data/task_controller.dart';
import '../screens/permissions_screen.dart';
import '../services/notifications.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>().settings;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        Text('设置', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textColor)),
        const SizedBox(height: 4),
        const Text('提醒、数据与权限', style: TextStyle(fontSize: 11, color: SpaceColors.muted)),
        const SizedBox(height: 10),
        const SectionTitle('提醒'),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              SettingSwitchRow(
                title: '任务提醒总开关',
                subtitle: '关闭后所有提醒暂停',
                value: settings.reminderMasterOn,
                onChanged: (value) async {
                  await context.read<SettingsController>().setReminderMaster(value);
                  if (context.mounted) await context.read<TaskController>().scheduleNotifications();
                },
              ),
              const RowDivider(),
              SettingSwitchRow(
                title: '震动',
                subtitle: '提醒时是否震动',
                value: settings.vibrationOn,
                onChanged: (value) async {
                  await context.read<SettingsController>().setVibration(value);
                  if (context.mounted) await context.read<TaskController>().scheduleNotifications();
                },
              ),
              const RowDivider(),
              SettingNavRow(
                title: '默认提醒时间',
                value: settings.defaultReminderTime,
                onTap: () async {
                  final parts = settings.defaultReminderTime.split(':');
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: int.tryParse(parts.first) ?? 9,
                      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
                    ),
                  );
                  if (picked != null && context.mounted) {
                    await context.read<SettingsController>().setDefaultReminderTime(
                          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                        );
                  }
                },
              ),
              const RowDivider(),
              const SettingNavRow(
                title: '提醒铃声',
                value: '系统默认',
              ),
              const RowDivider(),
              SettingNavRow(
                title: '提醒权限检查',
                value: '通知 / 精确闹钟 / 电池',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PermissionsScreen()),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('数据'),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              SettingNavRow(
                title: '清除所有任务',
                value: '',
                onTap: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: '清除所有任务',
                    message: '将删除全部任务和完成记录，统计会清零。这个操作不能撤销。',
                    confirmText: '全部清除',
                    destructive: true,
                  );
                  if (ok && context.mounted) {
                    await context.read<TaskController>().clearAllTasks();
                  }
                },
              ),
              const RowDivider(),
              SettingNavRow(
                title: '清除已完成任务',
                value: '',
                onTap: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: '清除已完成任务',
                    message: '将删除全部完成记录，所有勾选和统计会清零，任务本身保留。',
                    confirmText: '清除记录',
                    destructive: true,
                  );
                  if (ok && context.mounted) {
                    await context.read<TaskController>().clearCompleted();
                  }
                },
              ),
              const RowDivider(),
              SettingNavRow(
                title: '大西洋Fire！',
                value: '格式化',
                valueColor: SpaceColors.danger,
                onTap: () => _wipe(context),
              ),
            ],
          ),
        ),
        const SectionTitle('关于'),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: const Column(
            children: [
              SettingNavRow(title: '应用', value: '便宜启程 v1.0.0'),
              RowDivider(),
              SettingNavRow(title: '数据', value: '全部保存在本机'),
              RowDivider(),
              SettingNavRow(title: '隐私', value: '不联网、不收集信息'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            '愿每一件小事，都能准时启程。',
            style: TextStyle(fontSize: 11, color: SpaceColors.muted.withValues(alpha: 0.8)),
          ),
        ),
      ],
    );
  }

  Future<void> _wipe(BuildContext context) async {
    final first = await showConfirmDialog(
      context,
      title: '大西洋Fire！',
      message: '格式化会删除所有任务、完成记录、记事本、歌曲、图片和自定义设置，且无法恢复。',
      confirmText: '继续',
      destructive: true,
    );
    if (!first || !context.mounted) return;
    final second = await showConfirmDialog(
      context,
      title: '最后确认',
      message: '真的要格式化全部数据吗？这是第二次确认，删除后无法找回。',
      confirmText: '格式化',
      destructive: true,
    );
    if (!second || !context.mounted) return;
    await AppDatabase.instance.clearAllTables();
    await FileStore.instance.clearAll();
    await context.read<SettingsController>().clear();
    await AppNotifications.instance.cancelAll();
    if (!context.mounted) return;
    await context.read<TaskController>().load();
    await context.read<NotesController>().load();
    await context.read<PlayerController>().reload();
  }
}
