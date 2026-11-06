import 'package:flutter/foundation.dart';

import 'file_store.dart';
import 'models.dart';
import 'repository.dart';

class NotesController extends ChangeNotifier {
  final AppRepository _repo = AppRepository.instance;
  final FileStore _files = FileStore.instance;

  List<Note> notes = [];
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    notes = await _repo.loadNotes();
    loading = false;
    notifyListeners();
  }

  Future<void> saveNote({
    required int id,
    required String text,
    required List<String> images,
  }) async {
    final result = await _repo.saveNote(id: id, text: text, images: images);
    for (final path in result.removedImages) {
      await _files.delete(path);
    }
    await load();
  }

  Future<void> deleteNote(Note note) async {
    final removed = await _repo.deleteNote(note.id);
    for (final path in removed) {
      await _files.delete(path);
    }
    await load();
  }

  Future<String?> importFile(String sourcePath) async {
    final path = await _files.copyPickedFile(sourcePath, 'notes');
    return path;
  }

  Future<String?> importBytes(Uint8List bytes) async {
    return _files.saveBytes(bytes, 'notes', extension: '.jpg');
  }

  Future<void> deleteFile(String path) => _files.delete(path);
}

