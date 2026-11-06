import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/player_controller.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _dragging = false;
  double _dragValue = 0;
  double? _speedValue;

  Future<void> _importSongs() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    final paths = result.map((file) => file.path).whereType<String>().toList();
    if (paths.isEmpty) return;
    final count = await context.read<PlayerController>().importFiles(paths);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(count > 0 ? '已导入 $count 首歌' : '导入失败，请确认是音频文件')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final textColor = Theme.of(context).colorScheme.onSurface;
    final songs = player.songs;
    final current = player.currentSong;
    final duration = player.duration.inMilliseconds > 0 ? player.duration : const Duration(seconds: 1);
    var position = _dragging ? Duration(milliseconds: _dragValue.round()) : player.position;
    if (position < Duration.zero) position = Duration.zero;
    if (position > duration) position = duration;
    final speed = _speedValue ?? player.speed;

    return Scaffold(
      backgroundColor: SpaceColors.deepSpace,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('rote听歌', style: TextStyle(fontSize: 20, color: textColor)),
        actions: [
          TextButton(
            onPressed: _importSongs,
            child: const Text('导入 MP3', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
      body: SafeArea(
        child: songs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyHint(title: '还没有歌曲', subtitle: '导入手机里的 MP3，就能在这里听'),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _importSongs, child: const Text('导入歌曲')),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                children: [
                  Center(
                    child: Container(
                      width: 176,
                      height: 176,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0A1730),
                        border: Border.all(color: SpaceColors.accent.withValues(alpha: 0.30)),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset('assets/images/tool_player.png', fit: BoxFit.cover),
                          Container(color: Colors.black.withValues(alpha: 0.18)),
                          const Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.music_note, size: 28, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    current?.title ?? '选一首开始',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
                  ),
                  Text(
                    current?.artist ?? '本地音乐 · ${songs.length} 首',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: SpaceColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) => setState(() {
                      _dragging = true;
                      _dragValue = value;
                    }),
                    onChangeEnd: (value) async {
                      await player.seekTo(Duration(milliseconds: value.round()));
                      if (mounted) setState(() => _dragging = false);
                    },
                  ),
                  Row(
                    children: [
                      Text(_format(position), style: const TextStyle(fontSize: 10, color: SpaceColors.muted)),
                      const Spacer(),
                      Text(_format(duration), style: const TextStyle(fontSize: 10, color: SpaceColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: player.previous,
                        icon: Icon(Icons.skip_previous, size: 34, color: textColor),
                      ),
                      const SizedBox(width: 18),
                      SizedBox(
                        width: 66,
                        height: 66,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            backgroundColor: SpaceColors.accent,
                            foregroundColor: const Color(0xFF04101F),
                          ),
                          onPressed: player.togglePlay,
                          child: Icon(
                            player.playing ? Icons.pause : Icons.play_arrow,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      IconButton(
                        onPressed: player.next,
                        icon: Icon(Icons.skip_next, size: 34, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('循环方式', style: TextStyle(fontSize: 11, color: SpaceColors.muted)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: PlayerLoopMode.values.map((mode) {
                      return ChoiceChip(
                        label: Text(_loopLabel(mode), style: const TextStyle(fontSize: 12)),
                        selected: player.settings.settings.playerLoopMode == mode,
                        onSelected: (_) => player.setLoopMode(mode),
                      );
                    }).toList(),
                  ),
                  if (player.settings.settings.playerLoopMode == PlayerLoopMode.selected)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        '勾选歌曲后，「循环选中」只在勾选的歌之间循环。',
                        style: TextStyle(fontSize: 10, color: SpaceColors.muted),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('播放速度', style: TextStyle(fontSize: 11, color: SpaceColors.muted)),
                      const Spacer(),
                      Text('${speed.toStringAsFixed(2)}x', style: const TextStyle(fontSize: 12, color: SpaceColors.accent)),
                    ],
                  ),
                  Slider(
                    value: speed.clamp(0.5, 2.0),
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    onChanged: (value) => setState(() => _speedValue = value),
                    onChangeEnd: (value) {
                      player.setSpeed(value);
                      setState(() => _speedValue = null);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('我的歌曲', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
                      const Spacer(),
                      Text('${songs.length} 首', style: const TextStyle(fontSize: 11, color: SpaceColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...songs.map((song) {
                    final isCurrent = song.id == player.currentSongId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: player.selectedSongIds.contains(song.id),
                              onChanged: (_) => player.toggleSelection(song.id),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => player.playSong(song),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isCurrent ? SpaceColors.accent : textColor,
                                        ),
                                      ),
                                      Text(
                                        song.artist.isEmpty ? '本地音乐' : song.artist,
                                        style: const TextStyle(fontSize: 10, color: SpaceColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => player.playSong(song),
                              icon: Icon(
                                isCurrent && player.playing ? Icons.graphic_eq : Icons.play_arrow,
                                size: 22,
                                color: isCurrent ? SpaceColors.accent : SpaceColors.muted,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final ok = await showConfirmDialog(
                                  context,
                                  title: '删除歌曲',
                                  message: '「${song.title}」会从 App 中删除，手机原文件不受影响。',
                                  confirmText: '删除',
                                  destructive: true,
                                );
                                if (ok && mounted) {
                                  await player.deleteSong(song);
                                }
                              },
                              icon: const Icon(Icons.delete_outline, size: 20, color: SpaceColors.muted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  String _format(Duration value) {
    final seconds = value.inSeconds.clamp(0, 359999);
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  String _loopLabel(PlayerLoopMode mode) => switch (mode) {
        PlayerLoopMode.off => '不循环',
        PlayerLoopMode.all => '列表循环',
        PlayerLoopMode.one => '单曲循环',
        PlayerLoopMode.selected => '循环选中',
      };
}
