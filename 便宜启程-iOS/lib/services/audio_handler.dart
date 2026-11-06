import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../data/models.dart';

class MusicHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  MusicHandler() {
    player.playbackEventStream.listen(
      _broadcast,
      onError: (Object error, StackTrace stack) {},
    );
    player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _items.length) {
        mediaItem.add(_items[index]);
      }
    });
  }

  final ja.AudioPlayer player = ja.AudioPlayer();
  final List<MediaItem> _items = [];

  Future<void> setQueue({
    required List<MediaItem> items,
    required List<ja.AudioSource> sources,
    required int index,
  }) async {
    if (sources.isEmpty) return;
    _items
      ..clear()
      ..addAll(items);
    queue.add(items);
    await player.setAudioSources(
      sources,
      initialIndex: index.clamp(0, sources.length - 1),
      initialPosition: Duration.zero,
    );
    if (_items.isNotEmpty) {
      mediaItem.add(_items[index.clamp(0, _items.length - 1)]);
    }
  }

  void _broadcast(ja.PlaybackEvent event) {
    final processing = switch (player.processingState) {
      ja.ProcessingState.idle => AudioProcessingState.idle,
      ja.ProcessingState.loading => AudioProcessingState.loading,
      ja.ProcessingState.buffering => AudioProcessingState.buffering,
      ja.ProcessingState.ready => AudioProcessingState.ready,
      ja.ProcessingState.completed => AudioProcessingState.completed,
    };
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processing,
        playing: player.playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
        queueIndex: player.currentIndex,
      ),
    );
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() => player.seekToNext();

  @override
  Future<void> skipToPrevious() => player.seekToPrevious();

  @override
  Future<void> setSpeed(double speed) => player.setSpeed(speed.clamp(0.5, 2.0));

  Future<void> applyLoopMode(PlayerLoopMode mode) {
    final loop = switch (mode) {
      PlayerLoopMode.one => ja.LoopMode.one,
      PlayerLoopMode.off => ja.LoopMode.off,
      PlayerLoopMode.all || PlayerLoopMode.selected => ja.LoopMode.all,
    };
    return player.setLoopMode(loop);
  }
}
