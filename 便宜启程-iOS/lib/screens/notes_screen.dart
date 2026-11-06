import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/file_store.dart';
import '../data/models.dart';
import '../data/notes_controller.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesController>().notes;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: SpaceColors.deepSpace,
      body: PageBackground(
        home: false,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('大西洋记事本', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: textColor)),
                            const Text('把平时复制的图片和文字收进来', style: TextStyle(fontSize: 10, color: SpaceColors.muted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: notes.isEmpty
                        ? const Center(
                            child: EmptyHint(title: '记事本还是空的', subtitle: '点右下角 +，写一条或粘贴剪贴板'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
                            itemCount: notes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final note = notes[index];
                              return GlassCard(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(builder: (_) => NoteEditorScreen(note: note)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (note.text.isNotEmpty)
                                      Text(
                                        note.text,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
                                      ),
                                    if (note.images.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        children: note.images.take(4).map((path) {
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.file(File(path), width: 64, height: 64, fit: BoxFit.cover),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      '${note.updatedAt.month.toString().padLeft(2, '0')}-${note.updatedAt.day.toString().padLeft(2, '0')} '
                                      '${note.updatedAt.hour.toString().padLeft(2, '0')}:${note.updatedAt.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(fontSize: 10, color: SpaceColors.muted.withValues(alpha: 0.8)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const NoteEditorScreen()),
                  ),
                  backgroundColor: SpaceColors.accent,
                  foregroundColor: const Color(0xFF04101F),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.note});
  final Note? note;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _text;
  late List<String> _images;
  late final Set<String> _originalImages;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.note?.text ?? '');
    _images = List<String>.from(widget.note?.images ?? const []);
    _originalImages = Set<String>.from(_images);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _addImages() async {
    final picked = await ImagePicker().pickMultiImage();
    for (final file in picked) {
      final path = await FileStore.instance.copyPickedFile(file.path, 'notes');
      _images.add(path);
    }
    if (mounted) setState(() {});
  }

  Future<void> _pasteText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      if (mounted) _toast('剪贴板是空的');
      return;
    }
    _text.text = _text.text.isEmpty ? text : '${_text.text}\n$text';
    setState(() {});
  }

  Future<void> _pasteImage() async {
    try {
      const channel = MethodChannel('qicheng/clipboard');
      final bytes = await channel.invokeMethod<Uint8List>('getImage');
      if (bytes == null || bytes.isEmpty) {
        if (mounted) _toast('剪贴板里没有图片');
        return;
      }
      final path = await FileStore.instance.saveBytes(bytes, 'notes');
      _images.add(path);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) _toast('读取剪贴板图片失败');
    }
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    if (text.isEmpty && _images.isEmpty) {
      _toast('写点什么再保存吧');
      return;
    }
    setState(() => _saving = true);
    await context.read<NotesController>().saveNote(
          id: widget.note?.id ?? 0,
          text: text,
          images: _images,
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final note = widget.note;
    if (note == null) return;
    final ok = await showConfirmDialog(
      context,
      title: '删除笔记',
      message: '这条笔记和里面的图片都会从 App 中删除，无法恢复。',
      confirmText: '删除',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await context.read<NotesController>().deleteNote(note);
    if (mounted) Navigator.pop(context);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: SpaceColors.deepSpace,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.note == null ? '新建笔记' : '编辑笔记', style: TextStyle(fontSize: 18, color: textColor)),
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () async {
            final leftovers = _images.where((path) => !_originalImages.contains(path)).toList();
            for (final path in leftovers) {
              await FileStore.instance.delete(path);
            }
            if (mounted) Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _text,
                maxLines: null,
                minLines: 8,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: '写点什么，或者点下面从剪贴板粘贴…',
                ),
              ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _images.map((path) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(File(path), width: 92, height: 92, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () async {
                              setState(() => _images.remove(path));
                              if (!_originalImages.contains(path)) {
                                await FileStore.instance.delete(path);
                              }
                            },
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                children: [
                  TextButton(onPressed: _addImages, child: const Text('添加图片')),
                  TextButton(onPressed: _pasteText, child: const Text('粘贴文字')),
                  TextButton(onPressed: _pasteImage, child: const Text('粘贴图片')),
                  if (widget.note != null)
                    TextButton(
                      onPressed: _delete,
                      child: const Text('删除', style: TextStyle(color: SpaceColors.danger)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '剪贴板里的文字会追加到上方；图片会复制一份保存到 App 内，原图删掉也不影响。',
                style: TextStyle(fontSize: 10, height: 1.6, color: SpaceColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
