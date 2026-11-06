import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/settings_controller.dart';
import '../services/notifications.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Map<Permission, PermissionStatus> _statuses = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final statuses = <Permission, PermissionStatus>{};
    final permissions = <Permission>[Permission.notification];
    if (Platform.isAndroid) {
      permissions.add(Permission.scheduleExactAlarm);
      permissions.add(Permission.ignoreBatteryOptimizations);
    }
    for (final permission in permissions) {
      statuses[permission] = await permission.status;
    }
    if (!mounted) return;
    setState(() {
      _statuses
        ..clear()
        ..addAll(statuses);
      _loading = false;
    });
  }

  bool _granted(Permission permission) => _statuses[permission]?.isGranted ?? false;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: const Color(0xFF04070F),
      appBar: AppBar(
        title: Text('提醒权限检查', style: TextStyle(fontSize: 19, color: textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          const Text(
            '提醒能不能准时弹出，取决于下面几项。建议全部允许，尤其是国产手机。',
            style: TextStyle(fontSize: 12, height: 1.6, color: SpaceColors.muted),
          ),
          const SizedBox(height: 16),
          _PermissionCard(
            title: '通知权限',
            description: '没有通知权限，到点不会有任何弹出。',
            granted: _granted(Permission.notification),
            actionLabel: _granted(Permission.notification) ? '去查看' : '去允许',
            onTap: () async {
              await AppNotifications.instance.requestPermissions();
              if (Platform.isIOS) {
                await openAppSettings();
              }
              await _refresh();
            },
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 12),
            _PermissionCard(
              title: '精确闹钟',
              description: '允许后提醒会在设定的那一分钟触发；否则可能延迟。',
              granted: _granted(Permission.scheduleExactAlarm),
              actionLabel: _granted(Permission.scheduleExactAlarm) ? '已开启' : '去允许',
              onTap: () async {
                await AppNotifications.instance.requestExactPermission();
                await _refresh();
              },
            ),
            const SizedBox(height: 12),
            _PermissionCard(
              title: '电池优化',
              description: '设为“不限制”，避免后台被系统冻结导致提醒迟到。',
              granted: _granted(Permission.ignoreBatteryOptimizations),
              actionLabel: _granted(Permission.ignoreBatteryOptimizations) ? '已设置' : '去设置',
              onTap: () async {
                await Permission.ignoreBatteryOptimizations.request();
                await _refresh();
              },
            ),
          ],
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('测试通知', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                const SizedBox(height: 6),
                const Text(
                  '发一条测试提醒，确认通知通道是通的。如果没有收到，请回到上面检查权限。',
                  style: TextStyle(fontSize: 11, height: 1.6, color: SpaceColors.muted),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: () async {
                    final settings = context.read<SettingsController>().settings;
                    await AppNotifications.instance.showTest(settings);
                  },
                  child: const Text('发送测试通知'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _refresh,
            child: const Text('刷新状态', style: TextStyle(color: SpaceColors.accent)),
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 4),
            const GlassCard(
              child: Text(
                '小米、华为、OPPO、vivo：还需要在系统设置里允许自启动，并在最近任务里锁定本应用。',
                style: TextStyle(fontSize: 12, height: 1.6, color: SpaceColors.muted),
              ),
            ),
          ],
          if (_loading) ...[
            const SizedBox(height: 12),
            const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
          ],
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.title,
    required this.description,
    required this.granted,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool granted;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (granted ? SpaceColors.accent : SpaceColors.danger).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        granted ? '已开启' : '待处理',
                        style: TextStyle(
                          fontSize: 9,
                          color: granted ? SpaceColors.accent : SpaceColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(description, style: const TextStyle(fontSize: 11, height: 1.6, color: SpaceColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonal(onPressed: onTap, child: Text(actionLabel, style: const TextStyle(fontSize: 11))),
        ],
      ),
    );
  }
}
