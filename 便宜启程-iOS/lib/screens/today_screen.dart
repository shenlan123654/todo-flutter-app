import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/file_store.dart';
import '../data/models.dart';
import '../data/settings_controller.dart';
import '../data/task_controller.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskController>();
    final settings = context.watch<SettingsController>().settings;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
              child: Row(
                children: [
                  ProgressRing(
                    progress: tasks.todayProgress.rate,
                    child: Text(
                      '${tasks.todayProgress.percent}%',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '今日任务',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tasks.todayProgress.done} / ${tasks.todayProgress.total} 已完成',
                          style: const TextStyle(fontSize: 14, color: SpaceColors.muted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fullDateLabel(tasks.today),
                          style: TextStyle(
                            fontSize: 11,
                            color: SpaceColors.muted.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.todayTasks.isEmpty
                  ? const Center(
                      child: EmptyHint(
                        title: '今天还没有任务',
                        subtitle: '点右下角的 + 添加第一件事',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
                      itemCount: tasks.todayTasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = tasks.todayTasks[index];
                        return _TaskCard(
                          task: task,
                          completed: tasks.doneIds.contains(task.id),
                          style: settings.checkboxStyle,
                          onToggle: () => context.read<TaskController>().toggle(task),
                          onEdit: () => _openEditor(context, task),
                          onDelete: () => _deleteTask(context, task),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 18,
          child: FloatingActionButton(
            onPressed: () => _openEditor(context, null),
            backgroundColor: SpaceColors.accent,
            foregroundColor: const Color(0xFF04101F),
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, Task? task) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF081226),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => TaskEditorSheet(initial: task),
    );
  }

  Future<void> _deleteTask(BuildContext context, Task task) async {
    final ok = await showConfirmDialog(
      context,
      title: '删除任务',
      message: '确定删除「${task.title}」吗？历史完成记录会保留在统计里。',
      confirmText: '删除',
      destructive: true,
    );
    if (ok && context.mounted) {
      await context.read<TaskController>().delete(task);
    }
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.completed,
    required this.style,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final bool completed;
  final CheckboxStyle style;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final border = completed ? SpaceColors.accent.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.14);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        onLongPress: onDelete,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: completed ? const Color(0xE60D2040) : const Color(0xB30A1730),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              _TaskIcon(task: task, completed: completed),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: completed ? 0.55 : 1),
                      ),
                    ),
                    if (task.note.isNotEmpty || task.reminderEnabled) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (task.reminderEnabled)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(Icons.alarm, size: 12, color: SpaceColors.muted),
                            ),
                          Expanded(
                            child: Text(
                              [
                                if (task.note.isNotEmpty) task.note,
                                if (task.reminderEnabled)
                                  task.repeatType == RepeatType.daily
                                      ? '每天 ${task.reminderTime}'
                                      : '${dateLabel(task.onceDate ?? DateTime.now())} ${task.reminderTime}',
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: SpaceColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TaskCheckbox(checked: completed, style: style, onToggle: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskIcon extends StatelessWidget {
  const _TaskIcon({required this.task, required this.completed});
  final Task task;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final file = File(task.iconValue);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: SpaceColors.accent.withValues(alpha: completed ? 0.06 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SpaceColors.accent.withValues(alpha: 0.16)),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: task.iconType == TaskIconType.png && file.existsSync()
          ? Image.file(file, fit: BoxFit.cover, width: 46, height: 46)
          : Text(task.iconValue, style: const TextStyle(fontSize: 24)),
    );
  }
}

const _emojiIcons = [
  '📖', '🏋️', '💧', '🥕', '🌙', '⏰', '🏃', '🧘', '✍️', '🎯', '💊', '🍎',
  '🥗', '☀️', '🌱', '🎸', '🎨', '💻', '📚', '🧹', '🛌', '🚿', '🦷', '💰',
  '📞', '🎂', '✈️', '🚶', '🧠', '🍵', '🐱', '🌊', '⭐', '🔥', '🎵', '🛒',
];

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({super.key, this.initial});
  final Task? initial;

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late TaskIconType _iconType;
  late String _iconValue;
  late RepeatType _repeat;
  late DateTime _onceDate;
  late bool _reminder;
  late TimeOfDay _time;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final settings = context.read<SettingsController>().settings;
    _title = TextEditingController(text: initial?.title ?? '');
    _note = TextEditingController(text: initial?.note ?? '');
    _iconType = initial?.iconType ?? TaskIconType.emoji;
    _iconValue = initial?.iconValue ?? '📖';
    _repeat = initial?.repeatType ?? RepeatType.daily;
    _onceDate = initial?.onceDate ?? DateTime.now();
    _reminder = initial?.reminderEnabled ?? true;
    _time = initial == null ? _parseTime(settings.defaultReminderTime) : _parseTime(initial.reminderTime);
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.initial == null ? '新建任务' : '编辑任务',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: _pickIcon,
                  child: Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: SpaceColors.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SpaceColors.accent.withValues(alpha: 0.35)),
                    ),
                    child: _iconType == TaskIconType.png
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(File(_iconValue), fit: BoxFit.cover, width: 56, height: 56),
                          )
                        : Text(_iconValue, style: const TextStyle(fontSize: 27)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: '任务名称', hintText: '例如：阅读 30 分钟'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(labelText: '备注（可选）'),
            ),
            const SizedBox(height: 16),
            Text('重复方式', style: TextStyle(fontSize: 12, color: SpaceColors.muted)),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('每天'),
                  selected: _repeat == RepeatType.daily,
                  onSelected: (_) => setState(() => _repeat = RepeatType.daily),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('仅一次'),
                  selected: _repeat == RepeatType.once,
                  onSelected: (_) => setState(() => _repeat = RepeatType.once),
                ),
              ],
            ),
            if (_repeat == RepeatType.once) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _onceDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _onceDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x660B1A33),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 18, color: SpaceColors.accent),
                      const SizedBox(width: 10),
                      const Text('日期', style: TextStyle(fontSize: 13, color: SpaceColors.muted)),
                      const Spacer(),
                      Text(dateLabel(_onceDate), style: const TextStyle(fontSize: 14, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('提醒我', style: TextStyle(fontSize: 15, color: textColor)),
                      Text(
                        _reminder ? '到点用通知提醒一次' : '不提醒',
                        style: const TextStyle(fontSize: 11, color: SpaceColors.muted),
                      ),
                    ],
                  ),
                ),
                Switch(value: _reminder, onChanged: (value) => setState(() => _reminder = value)),
              ],
            ),
            if (_reminder) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: _time);
                  if (picked != null) setState(() => _time = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x660B1A33),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 18, color: SpaceColors.accent),
                      const SizedBox(width: 10),
                      const Text('提醒时间', style: TextStyle(fontSize: 13, color: SpaceColors.muted)),
                      const Spacer(),
                      Text(
                        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 16, color: SpaceColors.accent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: SpaceColors.accent,
                  foregroundColor: const Color(0xFF04101F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saving ? null : _save,
                child: Text(widget.initial == null ? '添加到今日清单' : '保存修改'),
              ),
            ),
            if (widget.initial != null)
              TextButton(
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: '删除任务',
                    message: '确定删除「${widget.initial!.title}」吗？',
                    confirmText: '删除',
                    destructive: true,
                  );
                  if (ok && mounted) {
                    await context.read<TaskController>().delete(widget.initial!);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('删除这个任务', style: TextStyle(color: SpaceColors.danger)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickIcon() async {
    final result = await showDialog<IconPickResult>(
      context: context,
      builder: (context) => const _IconPickerDialog(),
    );
    if (result == null) return;
    setState(() {
      _iconType = result.type;
      _iconValue = result.value;
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    final task = Task(
      id: widget.initial?.id ?? 0,
      title: title,
      note: _note.text.trim(),
      iconType: _iconType,
      iconValue: _iconValue,
      repeatType: _repeat,
      onceDate: _repeat == RepeatType.once ? _onceDate : null,
      reminderEnabled: _reminder,
      reminderTime: '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
      createdAt: widget.initial?.createdAt ?? DateTime.now(),
      sortOrder: widget.initial?.sortOrder ?? 0,
    );
    await context.read<TaskController>().save(task);
    if (mounted) Navigator.pop(context);
  }
}

class IconPickResult {
  const IconPickResult(this.type, this.value);
  final TaskIconType type;
  final String value;
}

class _IconPickerDialog extends StatefulWidget {
  const _IconPickerDialog();

  @override
  State<_IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<_IconPickerDialog> {
  List<String> _imported = [];

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final icons = await FileStore.instance.listIcons();
    if (mounted) setState(() => _imported = icons);
  }

  Future<void> _importPng() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final path = await FileStore.instance.copyPickedFile(picked.path, 'icons');
    if (!mounted) return;
    Navigator.pop(context, IconPickResult(TaskIconType.png, path));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1730),
      title: const Text('选择任务图标', style: TextStyle(fontSize: 16, color: Colors.white)),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _emojiIcons
                    .map((emoji) => InkWell(
                          onTap: () => Navigator.pop(context, IconPickResult(TaskIconType.emoji, emoji)),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                          ),
                        ))
                    .toList(),
              ),
              if (_imported.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('我导入的图标', style: TextStyle(fontSize: 12, color: SpaceColors.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _imported
                      .map((path) => InkWell(
                            onTap: () => Navigator.pop(context, IconPickResult(TaskIconType.png, path)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(File(path), width: 42, height: 42, fit: BoxFit.cover),
                            ),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 14),
              TextButton(
                onPressed: _importPng,
                child: const Text('从相册导入 PNG', style: TextStyle(color: SpaceColors.accent)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭', style: TextStyle(color: SpaceColors.muted)),
        ),
      ],
    );
  }
}
