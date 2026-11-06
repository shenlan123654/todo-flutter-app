import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/file_store.dart';
import '../data/models.dart';
import '../data/player_controller.dart';
import '../data/settings_controller.dart';

class CustomizeScreen extends StatefulWidget {
  const CustomizeScreen({super.key});

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen> {
  final SettingsController _settings = SettingsController.instance;
  final FileStore _files = FileStore.instance;
  Future<List<String>>? _icons;
  double? _dim;
  double? _scale;

  @override
  void initState() {
    super.initState();
    _icons = _files.listIcons();
  }

  Future<void> _pickBackground({required bool home}) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final path = await _files.copyPickedFile(picked.path, 'backgrounds');
    await _settings.setBackground(home: home, path: path);
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final path = await _files.copyPickedFile(picked.path, 'icons');
    await _settings.setLogo(path);
  }

  Future<void> _importIcon() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _files.copyPickedFile(picked.path, 'icons');
    setState(() => _icons = _files.listIcons());
  }

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
    final settings = context.watch<SettingsController>().settings;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final dim = _dim ?? settings.backgroundDim;
    final scale = _scale ?? settings.fontScale;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        Text('自定义', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textColor)),
        const SizedBox(height: 4),
        const Text('把星空调成你喜欢的样子', style: TextStyle(fontSize: 11, color: SpaceColors.muted)),
        const SectionTitle('页面背景'),
        GlassCard(
          child: Column(
            children: [
              _BackgroundRow(
                title: '主页面',
                path: settings.homeBackground,
                onPick: () => _pickBackground(home: true),
                onClear: () => _settings.setBackground(home: true, path: null),
              ),
              const SizedBox(height: 12),
              _BackgroundRow(
                title: '其它页面',
                path: settings.otherBackground,
                onPick: () => _pickBackground(home: false),
                onClear: () => _settings.setBackground(home: false, path: null),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '背景暗化 ${(dim * 100).round()}%（越大文字越清楚）',
                  style: const TextStyle(fontSize: 11, color: SpaceColors.muted),
                ),
              ),
              Slider(
                value: dim,
                onChanged: (value) => setState(() => _dim = value),
                onChangeEnd: (value) => _settings.setBackgroundDim(value),
                max: 0.8,
              ),
            ],
          ),
        ),
        const SectionTitle('字体'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('颜色', style: TextStyle(fontSize: 12, color: SpaceColors.muted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                children: _fontPresets.map((preset) {
                  final selected = settings.fontColor == preset.color;
                  return InkWell(
                    onTap: () => _settings.setFontColor(preset.color),
                    child: Column(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Color(preset.color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? SpaceColors.accent : Colors.white.withValues(alpha: 0.2),
                              width: selected ? 2 : 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          preset.name,
                          style: TextStyle(fontSize: 9, color: selected ? SpaceColors.accent : SpaceColors.muted),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('字号 ${(scale * 100).round()}%', style: const TextStyle(fontSize: 11, color: SpaceColors.muted)),
              Slider(
                value: scale,
                min: 0.85,
                max: 1.35,
                onChanged: (value) => setState(() => _scale = value),
                onChangeEnd: (value) => _settings.setFontScale(value),
              ),
            ],
          ),
        ),
        const SectionTitle('任务方框'),
        GlassCard(
          child: Row(
            children: CheckboxStyle.values.map((style) {
              final selected = settings.checkboxStyle == style;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _settings.setCheckboxStyle(style),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? SpaceColors.accent.withValues(alpha: 0.10) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? SpaceColors.accent.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        TaskCheckbox(checked: true, style: style, onToggle: () {}),
                        const SizedBox(height: 8),
                        Text(
                          _styleLabel(style),
                          style: TextStyle(fontSize: 10, color: selected ? SpaceColors.accent : SpaceColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SectionTitle('App 图片'),
        GlassCard(
          child: Row(
            children: [
              const BrandLogo(size: 62),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('应用内 Logo', style: TextStyle(fontSize: 14, color: textColor)),
                    const SizedBox(height: 4),
                    Text(
                      settings.logoPath == null ? '默认使用 App 图标' : '已使用自定义图片',
                      style: const TextStyle(fontSize: 11, color: SpaceColors.muted),
                    ),
                    const Text('桌面图标固定，不能运行时替换', style: TextStyle(fontSize: 10, color: SpaceColors.muted)),
                  ],
                ),
              ),
              TextButton(onPressed: _pickLogo, child: const Text('选择')),
              if (settings.logoPath != null)
                TextButton(onPressed: () => _settings.setLogo(null), child: const Text('重置')),
            ],
          ),
        ),
        const SectionTitle('任务图标库'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('导入的 PNG 会出现在新建任务的图标选择里', style: TextStyle(fontSize: 11, color: SpaceColors.muted)),
              const SizedBox(height: 12),
              FutureBuilder<List<String>>(
                future: _icons,
                builder: (context, snapshot) {
                  final icons = snapshot.data ?? [];
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...icons.take(18).map((path) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(path), width: 46, height: 46, fit: BoxFit.cover),
                          )),
                      InkWell(
                        onTap: _importIcon,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: SpaceColors.accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SpaceColors.accent.withValues(alpha: 0.30)),
                          ),
                          child: const Icon(Icons.add, color: SpaceColors.accent),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SectionTitle('提醒铃声'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前铃声：系统默认', style: TextStyle(fontSize: 14, color: textColor)),
              const SizedBox(height: 6),
              const Text(
                'Flutter 版先使用系统通知铃声；iOS 本身也不允许运行时导入铃声，安卓的自定义导入会在后续补上。',
                style: TextStyle(fontSize: 10, height: 1.6, color: SpaceColors.muted),
              ),
            ],
          ),
        ),
        const SectionTitle('歌曲（rote听歌）'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('导入的 MP3 会复制到 App 内，在「其它工具 → rote听歌」播放。', style: TextStyle(fontSize: 11, height: 1.6, color: SpaceColors.muted)),
              const SizedBox(height: 8),
              TextButton(onPressed: _importSongs, child: const Text('导入歌曲')),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  String _styleLabel(CheckboxStyle style) => switch (style) {
        CheckboxStyle.square => '方形',
        CheckboxStyle.rounded => '圆形',
        CheckboxStyle.dot => '圆点',
        CheckboxStyle.outline => '描边',
      };
}

class _BackgroundRow extends StatelessWidget {
  const _BackgroundRow({
    required this.title,
    required this.path,
    required this.onPick,
    required this.onClear,
  });

  final String title;
  final String? path;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final file = path == null ? null : File(path!);
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF0E1D38),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: file != null && file.existsSync()
              ? Image.file(file, width: 58, height: 58, fit: BoxFit.cover)
              : const Text('星空', style: TextStyle(fontSize: 10, color: SpaceColors.muted)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: textColor)),
              const SizedBox(height: 3),
              Text(
                file != null ? '已使用自定义图片' : '默认深空星空',
                style: const TextStyle(fontSize: 11, color: SpaceColors.muted),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onPick, child: Text(path == null ? '选择' : '更换')),
        if (path != null)
          IconButton(onPressed: onClear, icon: const Icon(Icons.close, size: 18, color: SpaceColors.muted)),
      ],
    );
  }
}

class _FontPreset {
  const _FontPreset(this.name, this.color);
  final String name;
  final int color;
}

const _fontPresets = [
  _FontPreset('月光白', 0xFFEAF6FF),
  _FontPreset('星蓝', 0xFF8FD8FF),
  _FontPreset('暖金', 0xFFF0D7A0),
  _FontPreset('薄荷', 0xFF9BE7C4),
  _FontPreset('樱粉', 0xFFFFB3C8),
];
