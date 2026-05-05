import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class Texture {
  final ui.Image image;

  Texture(this.image);

  int get width => image.width;

  int get height => image.height;

  void dispose() {
    image.dispose();
  }
}

class AssetManager {
  static const int _maxRetries = 30;
  static const Duration _retryDelay = Duration(seconds: 5);

  final Map<String, Texture> _texturesByPath = <String, Texture>{};
  final Map<String, Object> _loadErrorsByPath = <String, Object>{};
  final Map<String, int> _failureCounts = <String, int>{};
  final List<String> _queue = <String>[];
  final Set<String> _queuedSet = <String>{};

  Future<void>? _activeLoad;
  bool _batchOpen = false;
  int _batchRequested = 0;
  int _batchCompleted = 0;
  bool _disposed = false;

  void load(String path, Type type) {
    if (type != Texture) {
      return;
    }
    if (_texturesByPath.containsKey(path) || _queuedSet.contains(path)) {
      return;
    }
    if ((_failureCounts[path] ?? 0) >= _maxRetries) {
      return;
    }
    _loadErrorsByPath.remove(path);
    if (!_batchOpen && _queue.isEmpty && _activeLoad == null) {
      _batchOpen = true;
      _batchRequested = 0;
      _batchCompleted = 0;
    }
    _queue.add(path);
    _queuedSet.add(path);
    _batchRequested += 1;
  }

  bool update([int millis = 0]) {
    if (millis < 0) {
      millis = 0;
    }
    _pumpQueue();
    final bool done = _queue.isEmpty && _activeLoad == null;
    if (done) {
      _batchOpen = false;
    }
    return done;
  }

  double getProgress() {
    if (!_batchOpen || _batchRequested <= 0) {
      return 1;
    }
    return _batchCompleted / _batchRequested;
  }

  bool isLoaded(String path, Type type) {
    if (type != Texture) {
      return false;
    }
    return _texturesByPath.containsKey(path);
  }

  bool hasLoadError(String path) {
    return _loadErrorsByPath.containsKey(path);
  }

  Object? getLoadError(String path) {
    return _loadErrorsByPath[path];
  }

  Texture get(String path, Type type) {
    if (type != Texture) {
      throw StateError('Unsupported asset type for $path: $type');
    }
    final Texture? texture = _texturesByPath[path];
    if (texture == null) {
      throw StateError('Texture not loaded: $path');
    }
    return texture;
  }

  void unload(String path) {
    final Texture? texture = _texturesByPath.remove(path);
    texture?.dispose();
    _queuedSet.remove(path);
    _loadErrorsByPath.remove(path);
    _failureCounts.remove(path);
  }

  void dispose() {
    _disposed = true;
    for (final Texture texture in _texturesByPath.values) {
      texture.dispose();
    }
    _texturesByPath.clear();
    _loadErrorsByPath.clear();
    _failureCounts.clear();
    _queue.clear();
    _queuedSet.clear();
    _activeLoad = null;
    _batchOpen = false;
    _batchRequested = 0;
    _batchCompleted = 0;
  }

  void _pumpQueue() {
    if (_activeLoad != null || _queue.isEmpty) {
      return;
    }

    final String path = _queue.removeAt(0);
    _activeLoad = _loadTexture(path)
        .then((Texture texture) {
          _texturesByPath[path] = texture;
          _failureCounts.remove(path);
          _loadErrorsByPath.remove(path);
          _batchCompleted += 1;
        })
        .catchError((Object error) {
          final int count = (_failureCounts[path] ?? 0) + 1;
          _failureCounts[path] = count;
          _batchCompleted += 1;

          // ignore: avoid_print
          print(
            '[AssetManager] Failed to load $path (attempt $count/$_maxRetries): $error',
          );

          if (count < _maxRetries) {
            // Keep path in _queuedSet during the delay to block external re-queuing.
            // After the delay, evict rootBundle cache and re-queue for a fresh attempt.
            Future<void>.delayed(_retryDelay, () {
              if (_disposed || _texturesByPath.containsKey(path)) {
                return;
              }
              rootBundle.evict('assets/$path');
              _queuedSet.remove(path);
              if (!_batchOpen) {
                _batchOpen = true;
                _batchRequested = 0;
                _batchCompleted = 0;
              }
              _queue.add(path);
              _queuedSet.add(path);
              _batchRequested += 1;
              _pumpQueue();
            });
          } else {
            // All retries exhausted: surface the error and unblock _queuedSet.
            _loadErrorsByPath[path] = error;
            _queuedSet.remove(path);
            // ignore: avoid_print
            print('[AssetManager] Giving up on $path after $count attempts.');
          }
        })
        .whenComplete(() {
          _activeLoad = null;
          _pumpQueue();
        });
  }

  Future<Texture> _loadTexture(String path) async {
    final Uint8List bytes = await _readAssetBytes(path);
    if (bytes.isEmpty) {
      throw StateError('Asset $path is empty.');
    }
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return Texture(frameInfo.image);
  }

  // intentamos primero el rootBundle; si falla o devuelve vacio, leemos del disco
  // como fallback. Soluciona el problema de que dos instancias del .exe en debug
  // colisionen en el cache compartido del bundle y una vea bytes vacios.
  Future<Uint8List> _readAssetBytes(String path) async {
    try {
      final ByteData data = await rootBundle.load('assets/$path');
      final Uint8List bytes = data.buffer.asUint8List();
      if (bytes.isNotEmpty) {
        return bytes;
      }
    } catch (_) {
      // si el bundle peta seguimos con el fallback de disco
    }
    return _readAssetFromDisk(path);
  }

  Future<Uint8List> _readAssetFromDisk(String path) async {
    final String exeDir = File(Platform.resolvedExecutable).parent.path;
    final List<String> candidates = <String>[
      '$exeDir/data/flutter_assets/assets/$path',
      '$exeDir/Frameworks/App.framework/Resources/flutter_assets/assets/$path',
      '$exeDir/flutter_assets/assets/$path',
    ];
    for (final String candidate in candidates) {
      final File file = File(candidate);
      if (await file.exists()) {
        return file.readAsBytes();
      }
    }
    throw StateError('Asset $path not found on disk near $exeDir.');
  }
}
