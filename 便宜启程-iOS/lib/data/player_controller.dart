import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' show AudioSource;

import '../data/file_store.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../data/settings_controller.dart';
import '../services/audio_handler.dart';

class PlayerController extends ChangeNotifier {
  PlayerController(this.handler, this.settings) {
    _loadSongs();
    _subscriptions.add(handler.playbackState.listen((state) {
      _playing = state.playing;
      _position = state.updatePosition;
      _speed = state.speed;
      notifyListeners();
    }));
    _subscriptions.add(handler.mediaItem.listen((item) {
      _currentSongId = item == null ? null : int.tryParse(item.id);
      notifyListeners();
    }));
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_playing) {
        _position = handler.player.position;
        _duration = handler.player.duration ?? Duration.zero;
        notifyListeners();
      }
    });
    settings.addListener(_onSettingsChanged);
  }

  final MusicHandler handler;
  final SettingsController settings;
  final AppRepository _repo = AppRepository.instance;
  final FileStore _files = FileStore.instance;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _timer;

  List<Song> songs = [];
  List<Song> _queue = [];
  int? _currentSongId;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1;

  bool get playing => _playing;
  int? get currentSongId => _currentSongId;
  Duration get position => _position;
  Duration get duration => _duration;
  double get speed => _speed;
  List<Song> get queue => _queue;
  Set<int> get selectedSongIds => settings.settings.selectedSongIds;

  Song? get currentSong {
    final id = _currentSongId;
    if (id == null) return null;
    for (final song in songs) {
      if (song.id == id) return song;
    }
    return null;
  }

  Future<void> _loadSongs() async {
    songs = await _repo.loadSongs();
    notifyListeners();
  }

  Future<void> reload() => _loadSongs();

  void _onSettingsChanged() {
    handler.setSpeed(settings.settings.playerSpeed);
    handler.applyLoopMode(settings.settings.playerLoopMode);
    notifyListeners();
  }

  List<Song> _buildQueue(Song? clicked) {
    final mode = settings.settings.playerLoopMode;
    final selected = settings.settings.selectedSongIds;
    List<Song> base = songs;
    if (mode == PlayerLoopMode.selected && selected.isNotEmpty) {
      base = songs.where((song) => selected.contains(song.id)).toList();
      if (clicked != null && !base.any((song) => song.id == clicked.id)) {
        base = [clicked, ...base];
      }
    }
    return base;
  }

  Future<void> _startQueue(List<Song> queue, int index) async {
    _queue = queue;
    final items = <MediaItem>[];
    final sources = <AudioSource>[];
    for (final song in queue) {
      final item = MediaItem(
        id: song.id.toString(),
        title: song.title,
        artist: song.artist,
      );
      items.add(item);
      sources.add(AudioSource.file(song.filePath, tag: item));
    }
    await handler.setQueue(
      items: items,
      sources: sources,
      index: index.clamp(0, queue.length - 1),
    );
    await handler.applyLoopMode(settings.settings.playerLoopMode);
    await handler.play();
  }

  Future<void> playSong(Song song) async {
    if (songs.isEmpty) return;
    final queue = _buildQueue(song);
    final index = queue.indexWhere((item) => item.id == song.id);
    await _startQueue(queue, index < 0 ? 0 : index);
  }

  Future<void> togglePlay() async {
    if (handler.player.playing) {
      await handler.pause();
    } else if (handler.player.currentIndex == null && songs.isNotEmpty) {
      await playSong(songs.first);
    } else {
      await handler.play();
    }
  }

  Future<void> next() => handler.skipToNext();

  Future<void> previous() => handler.skipToPrevious();

  Future<void> seekTo(Duration position) => handler.seek(position);

  Future<void> setSpeed(double value) async {
    _speed = value.clamp(0.5, 2.0);
    notifyListeners();
    await handler.setSpeed(_speed);
    await settings.setPlayerSpeed(_speed);
  }

  Future<void> setLoopMode(PlayerLoopMode mode) async {
    await settings.setLoopMode(mode);
    await handler.applyLoopMode(mode);
    if (mode == PlayerLoopMode.selected) {
      final current = currentSong;
      if (current != null) {
        final queue = _buildQueue(current);
        final index = queue.indexWhere((song) => song.id == current.id);
        if (index >= 0) {
          _queue = queue;
          final items = <MediaItem>[];
          final sources = <AudioSource>[];
          for (final song in queue) {
            final item = MediaItem(id: song.id.toString(), title: song.title, artist: song.artist);
            items.add(item);
            sources.add(AudioSource.file(song.filePath, tag: item));
          }
          await handler.setQueue(items: items, sources: sources, index: index);
        }
      }
    }
  }

  Future<void> toggleSelection(int songId) async {
    final next = settings.settings.selectedSongIds.toSet();
    if (!next.add(songId)) next.remove(songId);
    await settings.setSelectedSongIds(next);
  }

  Future<int> importFiles(List<String> sourcePaths) async {
    var count = 0;
    for (final source in sourcePaths) {
      try {
        final saved = await _files.copyPickedFile(source, 'songs');
        final name = saved.split(RegExp(r'[/\\]')).last;
        final title = name.replaceFirst(RegExp(r'\.[^.]+$'), '');
        await _repo.insertSong(title: title, artist: '本地音乐', filePath: saved);
        count++;
      } catch (_) {}
    }
    await _loadSongs();
    return count;
  }

  Future<void> deleteSong(Song song) async {
    await _repo.deleteSong(song.id);
    await _files.delete(song.filePath);
    if (_currentSongId == song.id) {
      await handler.stop();
    }
    await _loadSongs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
