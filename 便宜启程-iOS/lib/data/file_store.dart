import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileStore {
  FileStore._();
  static final FileStore instance = FileStore._();

  Future<Directory> _sub(String name) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, name));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> copyPickedFile(String sourcePath, String subdir) async {
    final dir = await _sub(subdir);
    final ext = p.extension(sourcePath);
    final name = '${DateTime.now().microsecondsSinceEpoch}${ext.isEmpty ? '.bin' : ext}';
    final target = File(p.join(dir.path, name));
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  Future<String> saveBytes(Uint8List bytes, String subdir, {String extension = '.jpg'}) async {
    final dir = await _sub(subdir);
    final name = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final target = File(p.join(dir.path, name));
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  Future<String> saveText(String text, String subdir, {String extension = '.txt'}) async {
    final dir = await _sub(subdir);
    final name = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final target = File(p.join(dir.path, name));
    await target.writeAsString(text, flush: true);
    return target.path;
  }

  Future<List<String>> listIcons() async {
    final dir = await _sub('icons');
    final files = await dir.list().where((entity) => entity is File).toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files.map((file) => file.path).toList();
  }

  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<void> clearAll() async {
    final root = await getApplicationDocumentsDirectory();
    for (final name in ['images', 'icons', 'backgrounds', 'notes', 'songs']) {
      final dir = Directory(p.join(root.path, name));
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) await entity.delete();
        }
      }
    }
  }
}
