import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key, required this.onOpenPlayer, required this.onOpenNotes});
  final VoidCallback onOpenPlayer;
  final VoidCallback onOpenNotes;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        Text('其它工具', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textColor)),
        const SizedBox(height: 4),
        const Text('音乐与随手记，放在同一片星空下', style: TextStyle(fontSize: 11, color: SpaceColors.muted)),
        const SizedBox(height: 20),
        _ToolEntry(
          asset: 'assets/images/tool_player.png',
          title: 'rote听歌',
          subtitle: '导入本地 MP3，循环、倍速、后台播放',
          onTap: onOpenPlayer,
        ),
        const SizedBox(height: 14),
        _ToolEntry(
          asset: 'assets/images/tool_notes.png',
          title: '大西洋记事本',
          subtitle: '把平时复制的图片和文字，随手收进来',
          onTap: onOpenNotes,
        ),
        const SizedBox(height: 22),
        const Text(
          '这里以后还会继续加小工具。',
          style: TextStyle(fontSize: 11, color: SpaceColors.muted),
        ),
      ],
    );
  }
}

class _ToolEntry extends StatelessWidget {
  const _ToolEntry({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String asset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          ClipOval(child: Image.asset(asset, width: 72, height: 72, fit: BoxFit.cover)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: textColor)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: SpaceColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('已开放', style: TextStyle(fontSize: 9, color: SpaceColors.accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(fontSize: 11, height: 1.5, color: SpaceColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
