import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../database/database_helper.dart';

enum LoopModeState { off, all, one }

class PlaybackEngine extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  LoopModeState _loopMode = LoopModeState.off;
  bool _isShuffle = false;
  double _volume = 1.0;

  Song? get currentSong => (_currentIndex >= 0 && _currentIndex < _queue.length) ? _queue[_currentIndex] : null;
  List<Song> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  LoopModeState get loopMode => _loopMode;
  bool get isShuffle => _isShuffle;
  double get volume => _volume;

  PlaybackEngine() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();

      if (state.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
  }

  Future<void> setQueue(List<Song> songs, {int initialIndex = 0}) async {
    _queue = List.from(songs);
    _currentIndex = initialIndex;
    if (_queue.isNotEmpty && _currentIndex >= 0 && _currentIndex < _queue.length) {
      await _playCurrent();
    } else {
      await _audioPlayer.stop();
      _currentIndex = -1;
      notifyListeners();
    }
  }

  Future<void> playSong(Song song) async {
    final idx = _queue.indexWhere((s) => s.id == song.id);
    if (idx != -1) {
      _currentIndex = idx;
    } else {
      _queue.insert(_currentIndex + 1, song);
      _currentIndex = _currentIndex + 1;
    }
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (currentSong == null) return;
    final song = currentSong!;
    try {
      if (kIsWeb || song.filePath.startsWith('http') || song.filePath.startsWith('asset:')) {
        if (song.filePath.startsWith('asset:')) {
          await _audioPlayer.setAsset(song.filePath.replaceFirst('asset:', ''));
        } else {
          await _audioPlayer.setUrl(song.filePath);
        }
      } else {
        await _audioPlayer.setFilePath(song.filePath);
      }
      await _audioPlayer.play();
      DatabaseHelper.instance.recordRecentlyPlayed(song.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio file: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (currentSong != null) {
        await _audioPlayer.play();
      }
    }
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_loopMode == LoopModeState.one) {
      await seek(Duration.zero);
      await _audioPlayer.play();
      return;
    }
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
    } else {
      if (_loopMode == LoopModeState.all) {
        _currentIndex = 0;
      } else {
        await _audioPlayer.pause();
        return;
      }
    }
    await _playCurrent();
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (_currentIndex > 0) {
      _currentIndex--;
    } else {
      if (_loopMode == LoopModeState.all) {
        _currentIndex = _queue.length - 1;
      }
    }
    await _playCurrent();
  }

  void toggleLoopMode() {
    if (_loopMode == LoopModeState.off) {
      _loopMode = LoopModeState.all;
    } else if (_loopMode == LoopModeState.all) {
      _loopMode = LoopModeState.one;
    } else {
      _loopMode = LoopModeState.off;
    }
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    if (_isShuffle && _queue.isNotEmpty && currentSong != null) {
      final current = currentSong!;
      final rest = _queue.where((s) => s.id != current.id).toList()..shuffle();
      _queue = [current, ...rest];
      _currentIndex = 0;
    }
    notifyListeners();
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  void _onSongCompleted() {
    next();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
