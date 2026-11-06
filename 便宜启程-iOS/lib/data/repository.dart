import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import 'models.dart';
import 'database.dart';

class AppRepository {
  AppRepository._();
  static final AppRepository instance = AppRepository._();
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Task>> loadAllTasks() async {
    final db = await _db.database;
    final rows = await db.query('tasks', orderBy: 'sortOrder, id');
    return rows.map((row) {
      final repeatName = row['repeatType'] as String? ?? 'daily';
      final iconName = row['iconType'] as String? ?? 'emoji';
      return Task(
        id: row['id'] as int,
        title: row['title'] as String? ?? '',
        note: row['note'] as String? ?? '',
        iconType: TaskIconType.values.firstWhere(
          (value) => value.name == iconName,
          orElse: () => TaskIconType.emoji,
        ),
        iconValue: row['iconValue'] as String? ?? '馃摉',
        repeatType: RepeatType.values.firstWhere(
          (value) => value.name == repeatName,
          orElse: () => RepeatType.daily,
        ),
        onceDate: _parseDate(row['onceDate'] as String?),
        reminderEnabled: (row['reminderEnabled'] as int? ?? 0) == 1,
        reminderTime: row['reminderTime'] as String? ?? '09:00',
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int? ?? 0),
        deletedAt: (row['deletedAt'] as int?) == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row['deletedAt'] as int),
        sortOrder: row['sortOrder'] as int? ?? 0,
      );
    }).toList();
  }

  Future<int> insertTask(Task task) async {
    final db = await _db.database;
    return db.insert('tasks', _taskValues(task));
  }

  Future<void> updateTask(Task task) async {
    final db = await _db.database;
    await db.update('tasks', _taskValues(task), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> softDeleteTask(int id, DateTime deletedAt) async {
    final db = await _db.database;
    await db.update(
      'tasks',
      {'deletedAt': deletedAt.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Completion>> loadCompletions() async {
    final db = await _db.database;
    final rows = await db.query('completions');
    return rows
        .map((row) => Completion(
              taskId: row['taskId'] as int,
              date: DateTime.parse(row['date'] as String),
            ))
        .toList();
  }

  Future<void> setCompletion(int taskId, DateTime date, bool done) async {
    final db = await _db.database;
    final key = _formatDate(date);
    if (done) {
      await db.insert(
        'completions',
        {
          'taskId': taskId,
          'date': key,
          'completedAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.delete(
        'completions',
        where: 'taskId = ? AND date = ?',
        whereArgs: [taskId, key],
      );
    }
  }

  Future<void> clearTasks() async {
    final db = await _db.database;
    await db.delete('completions');
    await db.delete('tasks');
  }

  Future<void> clearCompletions() async {
    final db = await _db.database;
    await db.delete('completions');
  }

  Future<List<Note>> loadNotes() async {
    final db = await _db.database;
    final notes = await db.query('notes', orderBy: 'updatedAt DESC');
    final images = await db.query('note_images', orderBy: 'id');
    final byNote = <int, List<String>>{};
    for (final image in images) {
      byNote.putIfAbsent(image['noteId'] as int, () => []).add(image['filePath'] as String);
    }
    return notes
        .map((row) => Note(
              id: row['id'] as int,
              text: row['text'] as String? ?? '',
              createdAt: DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int? ?? 0),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updatedAt'] as int? ?? 0),
              images: byNote[row['id'] as int] ?? const [],
            ))
        .toList();
  }

  Future<NoteSaveResult> saveNote({
    required int id,
    required String text,
    required List<String> images,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final noteId = id == 0
        ? await db.insert('notes', {'text': text, 'createdAt': now, 'updatedAt': now})
        : id;
    if (id != 0) {
      await db.update(
        'notes',
        {'text': text, 'updatedAt': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    final stored = await db.query('note_images', where: 'noteId = ?', whereArgs: [noteId]);
    final storedPaths = stored.map((row) => row['filePath'] as String).toList();
    final removed = storedPaths.where((path) => !images.contains(path)).toList();
    for (final path in removed) {
      await db.delete(
        'note_images',
        where: 'noteId = ? AND filePath = ?',
        whereArgs: [noteId, path],
      );
    }
    for (final path in images.where((path) => !storedPaths.contains(path))) {
      await db.insert('note_images', {'noteId': noteId, 'filePath': path});
    }
    return NoteSaveResult(noteId, removed);
  }

  Future<List<String>> deleteNote(int id) async {
    final db = await _db.database;
    final images = await db.query('note_images', where: 'noteId = ?', whereArgs: [id]);
    final paths = images.map((row) => row['filePath'] as String).toList();
    await db.delete('note_images', where: 'noteId = ?', whereArgs: [id]);
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    return paths;
  }

  Future<List<Song>> loadSongs() async {
    final db = await _db.database;
    final rows = await db.query('songs', orderBy: 'addedAt DESC');
    return rows
        .map((row) => Song(
              id: row['id'] as int,
              title: row['title'] as String? ?? '',
              artist: row['artist'] as String? ?? '',
              filePath: row['filePath'] as String,
              durationMs: row['durationMs'] as int? ?? 0,
              addedAt: DateTime.fromMillisecondsSinceEpoch(row['addedAt'] as int? ?? 0),
            ))
        .toList();
  }

  Future<int> insertSong({
    required String title,
    required String artist,
    required String filePath,
    int durationMs = 0,
  }) async {
    final db = await _db.database;
    return db.insert('songs', {
      'title': title,
      'artist': artist,
      'filePath': filePath,
      'durationMs': durationMs,
      'addedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteSong(int id) async {
    final db = await _db.database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _taskValues(Task task) => {
        'title': task.title,
        'note': task.note,
        'iconType': task.iconType.name,
        'iconValue': task.iconValue,
        'repeatType': task.repeatType.name,
        'onceDate': task.onceDate == null ? null : _formatDate(task.onceDate!),
        'reminderEnabled': task.reminderEnabled ? 1 : 0,
        'reminderTime': task.reminderTime,
        'createdAt': task.createdAt.millisecondsSinceEpoch,
        'deletedAt': task.deletedAt?.millisecondsSinceEpoch,
        'sortOrder': task.sortOrder,
      };

  DateTime? _parseDate(String? value) => value == null ? null : DateTime.parse(value);

  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class NoteSaveResult {
  const NoteSaveResult(this.noteId, this.removedImages);
  final int noteId;
  final List<String> removedImages;
}

