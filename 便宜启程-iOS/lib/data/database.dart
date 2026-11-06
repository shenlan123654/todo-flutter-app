import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';


class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final dir = await getDatabasesPath();
    final file = p.join(dir, 'qicheng_flutter.db');
    final db = await openDatabase(
      file,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = OFF');
      },
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  title TEXT NOT NULL,
  note TEXT NOT NULL,
  iconType TEXT NOT NULL,
  iconValue TEXT NOT NULL,
  repeatType TEXT NOT NULL,
  onceDate TEXT,
  reminderEnabled INTEGER NOT NULL,
  reminderTime TEXT NOT NULL,
  createdAt INTEGER NOT NULL,
  deletedAt INTEGER,
  sortOrder INTEGER NOT NULL
)
''');
        await db.execute('''
CREATE TABLE completions (
  taskId INTEGER NOT NULL,
  date TEXT NOT NULL,
  completedAt INTEGER NOT NULL,
  PRIMARY KEY (taskId, date)
)
''');
        await db.execute('CREATE INDEX index_completions_date ON completions(date)');
        await db.execute('''
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  text TEXT NOT NULL,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
)
''');
        await db.execute('''
CREATE TABLE note_images (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  noteId INTEGER NOT NULL,
  filePath TEXT NOT NULL
)
''');
        await db.execute('CREATE INDEX index_note_images_noteId ON note_images(noteId)');
        await db.execute('''
CREATE TABLE songs (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  filePath TEXT NOT NULL,
  durationMs INTEGER NOT NULL,
  addedAt INTEGER NOT NULL
)
''');
      },
    );
    _database = db;
    return db;
  }

  Future<void> clearAllTables() async {
    final db = await database;
    await db.delete('completions');
    await db.delete('tasks');
    await db.delete('note_images');
    await db.delete('notes');
    await db.delete('songs');
  }
}
