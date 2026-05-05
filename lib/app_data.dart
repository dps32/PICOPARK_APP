import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'network_config.dart';
import 'utils_websockets.dart';

enum MatchPhase { connecting, waiting, playing, finished }

class MultiplayerPlayer {
  final String id;
  final String name;
  final double x;
  final double y;
  final double width;
  final double height;
  final int score;
  final int gemsCollected;
  final String direction;
  final String facing;
  final bool moving;
  final double velocityY;
  final bool onGround;
  final int joinOrder;
  final String winStage;

  const MultiplayerPlayer({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.score,
    required this.gemsCollected,
    required this.direction,
    required this.facing,
    required this.moving,
    required this.velocityY,
    required this.onGround,
    required this.joinOrder,
    this.winStage = 'none',
  });

  factory MultiplayerPlayer.fromJson(Map<String, dynamic> json) {
    return MultiplayerPlayer(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? 'Player').trim(),
      x: (json['x'] as num? ?? 0).toDouble(),
      y: (json['y'] as num? ?? 0).toDouble(),
      width: (json['width'] as num? ?? 20).toDouble(),
      height: (json['height'] as num? ?? 20).toDouble(),
      score: (json['score'] as num? ?? 0).toInt(),
      gemsCollected: (json['gemsCollected'] as num? ?? 0).toInt(),
      direction: (json['direction'] as String? ?? 'none').trim(),
      facing: (json['facing'] as String? ?? 'down').trim(),
      moving: json['moving'] as bool? ?? false,
      velocityY: (json['velocityY'] as num? ?? 0).toDouble(),
      onGround: json['onGround'] as bool? ?? true,
      joinOrder: (json['joinOrder'] as num? ?? 0).toInt(),
      winStage: (json['winStage'] as String? ?? 'none').trim(),
    );
  }
}

class MultiplayerGem {
  final String id;
  final String type;
  final double x;
  final double y;
  final double width;
  final double height;
  final int value;

  const MultiplayerGem({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.value,
  });

  factory MultiplayerGem.fromJson(Map<String, dynamic> json) {
    return MultiplayerGem(
      id: (json['id'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? 'green').trim().toLowerCase(),
      x: (json['x'] as num? ?? 0).toDouble(),
      y: (json['y'] as num? ?? 0).toDouble(),
      width: (json['width'] as num? ?? 15).toDouble(),
      height: (json['height'] as num? ?? 15).toDouble(),
      value: (json['value'] as num? ?? 1).toInt(),
    );
  }
}

class MultiplayerKey {
  final bool picked;
  final String carrierId;
  final double x;
  final double y;
  final double width;
  final double height;

  const MultiplayerKey({
    required this.picked,
    required this.carrierId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory MultiplayerKey.fromJson(Map<String, dynamic> json) {
    return MultiplayerKey(
      picked: json['picked'] as bool? ?? false,
      carrierId: (json['carrierId'] as String? ?? '').trim(),
      x: (json['x'] as num? ?? 0).toDouble(),
      y: (json['y'] as num? ?? 0).toDouble(),
      width: (json['width'] as num? ?? 16).toDouble(),
      height: (json['height'] as num? ?? 16).toDouble(),
    );
  }
}

class MultiplayerDoor {
  final bool enabled;
  final bool opened;
  final String carrierId;
  final int spriteIndex;
  final String animationId;
  final int openedAtTick;
  final int frameIndex;
  final double x;
  final double y;
  final double width;
  final double height;

  const MultiplayerDoor({
    required this.enabled,
    required this.opened,
    required this.carrierId,
    required this.spriteIndex,
    required this.animationId,
    required this.openedAtTick,
    required this.frameIndex,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory MultiplayerDoor.fromJson(Map<String, dynamic> json) {
    return MultiplayerDoor(
      enabled: json['enabled'] as bool? ?? false,
      opened: json['opened'] as bool? ?? false,
      carrierId: (json['carrierId'] as String? ?? '').trim(),
      spriteIndex: (json['spriteIndex'] as num? ?? -1).toInt(),
      animationId: (json['animationId'] as String? ?? '').trim(),
      openedAtTick: (json['openedAtTick'] as num? ?? 0).toInt(),
      frameIndex: (json['frameIndex'] as num? ?? 0).toInt(),
      x: (json['x'] as num? ?? 0).toDouble(),
      y: (json['y'] as num? ?? 0).toDouble(),
      width: (json['width'] as num? ?? 27).toDouble(),
      height: (json['height'] as num? ?? 39).toDouble(),
    );
  }
}

class TransformSnapshot {
  final int index;
  final double x;
  final double y;

  const TransformSnapshot({
    required this.index,
    required this.x,
    required this.y,
  });

  factory TransformSnapshot.fromJson(Map<String, dynamic> json) {
    return TransformSnapshot(
      index: (json['index'] as num? ?? -1).toInt(),
      x: (json['x'] as num? ?? 0).toDouble(),
      y: (json['y'] as num? ?? 0).toDouble(),
    );
  }
}

class _PlayerStaticData {
  final String id;
  final String name;
  final double width;
  final double height;
  final int joinOrder;

  const _PlayerStaticData({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.joinOrder,
  });
}

class _PlayerDynamicData {
  final String id;
  final double x;
  final double y;
  final int score;
  final int gemsCollected;
  final String direction;
  final String facing;
  final bool moving;
  final double velocityY;
  final bool onGround;
  final String winStage;

  const _PlayerDynamicData({
    required this.id,
    required this.x,
    required this.y,
    required this.score,
    required this.gemsCollected,
    required this.direction,
    required this.facing,
    required this.moving,
    required this.velocityY,
    required this.onGround,
    this.winStage = 'none',
  });
}

class _LocalBotProfile {
  final String id;
  final String name;

  const _LocalBotProfile({required this.id, required this.name});
}

class AppData extends ChangeNotifier {
  static const int _minimumPlayersRequired = 2;

  final WebSocketsHandler _wsHandler = WebSocketsHandler();
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = const Duration(seconds: 3);

  NetworkConfig networkConfig;
  String playerName;

  bool isConnected = false;
  bool isConnecting = false;
  String? playerId;
  String? roomCode;
  String roomStatus = 'connecting';
  String? roomErrorMessage;
  int minPlayers = _minimumPlayersRequired;
  int maxPlayers = 8;
  bool isRoomHost = false;
  MatchPhase phase = MatchPhase.connecting;
  String levelName = 'All together now';
  int countdownSeconds = 60;
  int remainingGems = 0;
  String? winnerId;
  List<MultiplayerPlayer> players = const <MultiplayerPlayer>[];
  List<MultiplayerGem> gems = const <MultiplayerGem>[];
  MultiplayerKey? matchKey;
  MultiplayerDoor? matchDoor;
  List<TransformSnapshot> layerTransforms = const <TransformSnapshot>[];
  List<TransformSnapshot> zoneTransforms = const <TransformSnapshot>[];

  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;
  bool _wasKicked = false;
  bool _disposed = false;
  bool _registrationSent = false;
  String _lastDirection = 'none';
  Timer? _connectionRetryTimer;

  // Whether the player was kicked by the server (suppresses reconnect UI).
  bool get wasKicked => _wasKicked;
  final List<_LocalBotProfile> _localBotPool = const <_LocalBotProfile>[
    _LocalBotProfile(id: 'bot_local_1', name: 'Bot Kiwi'),
    _LocalBotProfile(id: 'bot_local_2', name: 'Bot Mango'),
    _LocalBotProfile(id: 'bot_local_3', name: 'Bot Peach'),
    _LocalBotProfile(id: 'bot_local_4', name: 'Bot Berry'),
  ];
  Map<String, _PlayerStaticData> _playerStaticById =
      const <String, _PlayerStaticData>{};
  Map<String, _PlayerDynamicData> _playerDynamicById =
      const <String, _PlayerDynamicData>{};

  AppData({NetworkConfig initialConfig = NetworkConfig.defaults})
    : networkConfig = initialConfig,
      playerName = initialConfig.playerName {
    _connectToWebSocket();
  }

  MultiplayerPlayer? get localPlayer {
    final String? id = playerId;
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final MultiplayerPlayer player in players) {
      if (player.id == id) {
        return player;
      }
    }
    return null;
  }

  List<MultiplayerPlayer> get sortedPlayers {
    final List<MultiplayerPlayer> sorted = List<MultiplayerPlayer>.from(
      players,
    );
    sorted.sort((MultiplayerPlayer a, MultiplayerPlayer b) {
      final int byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }
      final int byGems = b.gemsCollected.compareTo(a.gemsCollected);
      if (byGems != 0) {
        return byGems;
      }
      final int byJoinOrder = a.joinOrder.compareTo(b.joinOrder);
      if (byJoinOrder != 0) {
        return byJoinOrder;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  bool get canMove => isConnected && phase == MatchPhase.playing;

  bool get canRequestMatchStart =>
      isConnected &&
      phase == MatchPhase.waiting &&
      players.length >= minPlayers;

  bool get canRequestMatchRestart =>
      isConnected && phase == MatchPhase.finished;

  String get roomLabel {
    return 'GLOBAL';
  }

  bool get _shouldUseLocalBots => false;

  void updateNetworkConfig(NetworkConfig nextConfig) {
    networkConfig = nextConfig;
    playerName = nextConfig.playerName;
    _reconnectAttempts = 0;
    playerId = null;
    _lastDirection = 'none';
    disconnect();
    _connectToWebSocket();
  }

  /// Actualiza la dirección de movimiento del jugador local
  /// Normaliza el valor y lo envía al servidor
  /// La dirección puede ser 'left', 'right' o 'none'
  void updateMovementDirection(String direction) {
    final String normalized = _normalizeDirection(direction);
    if (_lastDirection == normalized) {
      return;
    }
    _lastDirection = normalized;
    _sendMessage(<String, dynamic>{'type': 'direction', 'value': normalized});
  }

  /// Solicita un salto para el jugador local
  /// Solo se ejecuta si el jugador puede moverse
  /// El servidor es responsable de validar si el salto es válido
  void requestJump() {
    if (!canMove) {
      return;
    }
    _sendMessage(<String, dynamic>{'type': 'jump'});
  }

  void requestMatchRestart() {
    if (!canRequestMatchRestart) {
      return;
    }
    _sendMessage(<String, dynamic>{'type': 'restartMatch'});
  }

  void requestMatchStart() {
    if (!canRequestMatchStart) {
      if (kDebugMode) {
        print(
          '[PLAY BUTTON] No es pot iniciar: isConnected=$isConnected, phase=$phase, isRoomHost=$isRoomHost, players=$players.length/$minPlayers',
        );
      }
      return;
    }

    if (_shouldUseLocalBots) {
      if (kDebugMode) {
        print(
          '[LOCAL MODE] Inicia partida localment amb ${players.length} jugadors (${players.where((p) => p.id.startsWith('bot_')).length} bots)',
        );
      }
      roomStatus = 'in_game';
      phase = MatchPhase.playing;
      notifyListeners();
      return;
    }

    if (kDebugMode) {
      print('[REMOTE MODE] Enviant startMatch al servidor');
    }
    _sendMessage(<String, dynamic>{'type': 'startMatch'});
  }

  void disconnect() {
    _intentionalDisconnect = true;
    stopRetryTimer();
    _lastDirection = 'none';
    _registrationSent = false;
    _wsHandler.disconnectFromServer();
    isConnected = false;
    isConnecting = false;
    roomCode = null;
    roomStatus = 'connecting';
    roomErrorMessage = null;
    minPlayers = _minimumPlayersRequired;
    maxPlayers = 8;
    isRoomHost = false;
    players = const <MultiplayerPlayer>[];
    gems = const <MultiplayerGem>[];
    matchKey = null;
    matchDoor = null;
    _playerStaticById = const <String, _PlayerStaticData>{};
    _playerDynamicById = const <String, _PlayerDynamicData>{};
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopRetryTimer();
    disconnect();
    super.dispose();
  }

  // Starts a periodic timer that keeps trying to connect while the player is
  // on the waiting room screen and not yet connected.
  void startConnectionRetryTimer() {
    if (_connectionRetryTimer != null) return;
    _connectionRetryTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_disposed || _wasKicked) {
        stopRetryTimer();
        return;
      }
      if (!isConnected && !isConnecting) {
        _reconnectAttempts = 0;
        _connectToWebSocket();
      }
    });
  }

  void stopRetryTimer() {
    _connectionRetryTimer?.cancel();
    _connectionRetryTimer = null;
  }

  void _connectToWebSocket() {
    if (_disposed || _wasKicked) {
      return;
    }
    if (isConnected || isConnecting) {
      return;
    }
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print("S'ha assolit el màxim d'intents de reconnexió.");
      }
      return;
    }

    _intentionalDisconnect = false;
    _wasKicked = false;
    _registrationSent = false;
    isConnecting = true;
    isConnected = false;
    phase = MatchPhase.connecting;
    roomErrorMessage = null;

    if (_shouldUseLocalBots) {
      if (kDebugMode) {
        print('[LOCAL MODE] Inicialitzant mode local amb bots');
        print(
          '[LOCAL MODE] Minimum de jugadors requerits: $_minimumPlayersRequired',
        );
      }
    } else {
      if (kDebugMode) {
        print(
          '[REMOTE MODE] Connectant a servidor remot: ${networkConfig.serverHost}:${networkConfig.serverPort}',
        );
      }
    }

    notifyListeners();

    if (_shouldUseLocalBots) {
      if (kDebugMode) {
        print(
          '[LOCAL MODE] Saltant connexió WebSocket, registrant jugador localment',
        );
      }
      _initializeLocalMode();
      return;
    }

    _wsHandler.connectToServer(
      networkConfig.serverHost,
      networkConfig.serverPort,
      _onWebSocketMessage,
      useSecureSocket: networkConfig.useSecureWebSocket,
      onError: _onWebSocketError,
      onDone: _onWebSocketClosed,
    );
  }

  void _initializeLocalMode() {
    if (_disposed) {
      return;
    }

    if (kDebugMode) {
      print('[LOCAL MODE] Inicialitzant estat local');
    }

    _markConnected();
    playerId = 'local_player_${DateTime.now().millisecondsSinceEpoch}';
    roomCode = 'LOCAL';
    roomStatus = 'in_game';
    phase = MatchPhase.playing;
    isRoomHost = true;
    minPlayers = _minimumPlayersRequired;
    maxPlayers = 8;

    final MultiplayerPlayer localPlayer = MultiplayerPlayer(
      id: playerId!,
      name: playerName,
      x: 120,
      y: 120,
      width: 20,
      height: 20,
      score: 0,
      gemsCollected: 0,
      direction: 'none',
      facing: 'down',
      moving: false,
      velocityY: 0,
      onGround: true,
      joinOrder: 0,
    );

    _playerStaticById = <String, _PlayerStaticData>{
      playerId!: _PlayerStaticData(
        id: playerId!,
        name: playerName,
        width: 20,
        height: 20,
        joinOrder: 0,
      ),
    };

    _playerDynamicById = <String, _PlayerDynamicData>{
      playerId!: _PlayerDynamicData(
        id: playerId!,
        x: 120,
        y: 120,
        score: 0,
        gemsCollected: 0,
        direction: 'none',
        facing: 'down',
        moving: false,
        velocityY: 0,
        onGround: true,
      ),
    };

    players = _applyLocalBots(<MultiplayerPlayer>[localPlayer]);

    if (kDebugMode) {
      print('[LOCAL MODE] Jugador local registrat: $playerId ($playerName)');
    }

    notifyListeners();
  }

  void _onWebSocketMessage(String message) {
    try {
      final Object? decoded = jsonDecode(message);
      if (decoded is! Map) {
        return;
      }
      final Map<String, dynamic> data = _mapFromDynamic(decoded);

      final String type = _readMessageType(data);
      final Map<String, dynamic> payload = _readPayload(data);

      if (type == 'welcome' || type == 'server:connected') {
        _markConnected();
        final String candidateId =
            (payload['socketId'] as String? ?? _wsHandler.socketId ?? '')
                .trim();
        if (candidateId.isNotEmpty) {
          // Always overwrite: a new welcome means a new server session/ID.
          // Using ??= here would leave a stale ID from a previous connection
          // and cause a ghost player in _playerDynamicById.
          playerId = candidateId;
          // Clear dynamic state so stale IDs from the old session don't leak
          // into _rebuildPlayers via the static ∪ dynamic union.
          _playerStaticById = const <String, _PlayerStaticData>{};
          _playerDynamicById = const <String, _PlayerDynamicData>{};
        }
        minPlayers = math.max(
          _minimumPlayersRequired,
          (payload['minPlayers'] as num? ?? minPlayers).toInt(),
        );
        maxPlayers = (payload['maxPlayers'] as num? ?? maxPlayers).toInt();
        _registerPlayer();
        notifyListeners();
        return;
      }

      if (type == 'room:created' || type == 'room:joined') {
        _markConnected();
        final String code = (payload['roomCode'] as String? ?? '').trim();
        if (code.isNotEmpty) {
          roomCode = code;
        }
        roomStatus = 'lobby';
        phase = MatchPhase.waiting;
        notifyListeners();
        return;
      }

      if (type == 'room:update') {
        _markConnected();
        _applyRoomUpdate(payload);
        notifyListeners();
        return;
      }

      if (type == 'room:started') {
        _markConnected();
        roomStatus = 'in_game';
        phase = MatchPhase.playing;
        notifyListeners();
        return;
      }

      if (type == 'kicked') {
        // Server kicked us — mark as kicked so neither auto-reconnect nor the
        // retry timer attempt to reconnect. The socket will close right after.
        _wasKicked = true;
        _intentionalDisconnect = true;
        return;
      }

      if (type == 'room:error') {
        roomErrorMessage =
            (payload['message'] as String? ?? 'Unknown room error').trim();
        notifyListeners();
        return;
      }

      if (type == 'snapshot' || type == 'initial') {
        _markConnected();
        final Object? rawSnapshot = data['snapshot'] ?? data['initialState'];
        _applySnapshotState(
          rawSnapshot is Map ? _mapFromDynamic(rawSnapshot) : {},
        );
        notifyListeners();
        return;
      }

      if (type == 'gameplay') {
        _markConnected();
        final Object? rawGameState = data['gameState'];
        _applyGameplayState(
          rawGameState is Map ? _mapFromDynamic(rawGameState) : {},
        );
        notifyListeners();
        return;
      }

      if (type == 'update') {
        _markConnected();
        final Object? rawGameState = data['gameState'];
        final Map<String, dynamic> gameState = rawGameState is Map
            ? _mapFromDynamic(rawGameState)
            : {};
        _applySnapshotState(gameState);
        _applyGameplayState(gameState);
        notifyListeners();
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error processant missatge WebSocket: $error');
      }
    }
  }

  void _markConnected() {
    isConnected = true;
    isConnecting = false;
    _reconnectAttempts = 0;
  }

  String _readMessageType(Map<String, dynamic> data) {
    final String directType = (data['type'] as String? ?? '').trim();
    if (directType.isNotEmpty) {
      return directType;
    }
    return (data['event'] as String? ?? '').trim();
  }

  Map<String, dynamic> _readPayload(Map<String, dynamic> data) {
    final Object? payload = data['payload'];
    if (payload is Map) {
      return _mapFromDynamic(payload);
    }
    return data;
  }

  void _applyRoomUpdate(Map<String, dynamic> room) {
    final String candidateRoomCode = (room['roomCode'] as String? ?? '').trim();
    if (candidateRoomCode.isNotEmpty) {
      roomCode = candidateRoomCode;
    }

    minPlayers = math.max(
      _minimumPlayersRequired,
      (room['minPlayers'] as num? ?? minPlayers).toInt(),
    );
    maxPlayers = (room['maxPlayers'] as num? ?? maxPlayers).toInt();

    roomStatus = (room['status'] as String? ?? 'lobby').trim();
    phase = roomStatus == 'in_game' ? MatchPhase.playing : MatchPhase.waiting;

    final String hostId = (room['hostSocketId'] as String? ?? '').trim();
    final String localId = (playerId ?? _wsHandler.socketId ?? '').trim();
    if (localId.isNotEmpty) {
      playerId = localId;
      isRoomHost = hostId.isNotEmpty && hostId == localId;
    }

    final List<dynamic> roomPlayers =
        room['players'] as List<dynamic>? ?? const <dynamic>[];

    final Map<String, _PlayerStaticData> staticById =
        <String, _PlayerStaticData>{};
    final Map<String, _PlayerDynamicData> dynamicById =
        <String, _PlayerDynamicData>{};

    int joinOrder = 0;
    for (final Map rawPlayer in roomPlayers.whereType<Map>()) {
      final Map<String, dynamic> player = _mapFromDynamic(rawPlayer);
      final String id =
          (player['socketId'] as String? ?? player['id'] as String? ?? '')
              .trim();
      if (id.isEmpty) {
        continue;
      }

      final String name =
          (player['nickname'] as String? ??
                  player['name'] as String? ??
                  'Player')
              .trim();
      final int playerJoinOrder = (player['joinOrder'] as num? ?? joinOrder)
          .toInt();
      final bool playerIsHost = player['isHost'] as bool? ?? false;
      if (!isRoomHost && localId.isNotEmpty && id == localId) {
        isRoomHost = playerIsHost;
      }

      staticById[id] = _PlayerStaticData(
        id: id,
        name: name,
        width: (player['width'] as num? ?? 20).toDouble(),
        height: (player['height'] as num? ?? 20).toDouble(),
        joinOrder: playerJoinOrder,
      );
      dynamicById[id] = _PlayerDynamicData(
        id: id,
        x: (player['x'] as num? ?? 0).toDouble(),
        y: (player['y'] as num? ?? 0).toDouble(),
        score: (player['score'] as num? ?? 0).toInt(),
        gemsCollected: (player['gemsCollected'] as num? ?? 0).toInt(),
        direction: (player['direction'] as String? ?? 'none').trim(),
        facing: (player['facing'] as String? ?? 'down').trim(),
        moving: player['moving'] as bool? ?? false,
        velocityY: (player['velocityY'] as num? ?? 0).toDouble(),
        onGround: player['onGround'] as bool? ?? true,
        winStage: (player['winStage'] as String? ?? 'none').trim(),
      );
      joinOrder++;
    }

    _playerStaticById = staticById;
    _playerDynamicById = dynamicById;
    _rebuildPlayers();
  }

  void _applySnapshotState(Map<String, dynamic> state) {
    levelName = (state['level'] as String? ?? levelName).trim();

    if (state.containsKey('players')) {
      final List<dynamic> rawPlayers = state['players'] as List<dynamic>? ?? [];
      _playerStaticById = <String, _PlayerStaticData>{
        for (final Map rawPlayer in rawPlayers.whereType<Map>())
          (_mapFromDynamic(rawPlayer)['id'] as String? ?? '').trim():
              _staticPlayerFromJson(_mapFromDynamic(rawPlayer)),
      }..remove('');
      _playerDynamicById = Map<String, _PlayerDynamicData>.fromEntries(
        _playerDynamicById.entries.where(
          (MapEntry<String, _PlayerDynamicData> entry) =>
              _playerStaticById.containsKey(entry.key),
        ),
      );
    }

    if (state.containsKey('gems')) {
      gems = _parseGems(state['gems'] as List<dynamic>?);
    }

    _rebuildPlayers();
  }

  void _applyGameplayState(Map<String, dynamic> state) {
    levelName = (state['level'] as String? ?? levelName).trim();
    phase = _parsePhase(state['phase'] as String?);
    countdownSeconds = (state['countdownSeconds'] as num? ?? 0).toInt();
    remainingGems =
        (state['remainingGems'] as num? ?? state['gems']?.length ?? 0).toInt();
    winnerId = state['winnerId'] as String?;
    final Object? rawKey = state['key'];
    matchKey = rawKey is Map
        ? MultiplayerKey.fromJson(_mapFromDynamic(rawKey))
        : null;
    final Object? rawDoor = state['door'];
    matchDoor = rawDoor is Map
      ? MultiplayerDoor.fromJson(_mapFromDynamic(rawDoor))
      : null;

    // Start from an empty map when we have a known static set, so that stale
    // IDs from previous connections never sneak in via the union in _rebuildPlayers.
    final Map<String, _PlayerDynamicData> nextDynamicById =
        _playerStaticById.isNotEmpty
            ? <String, _PlayerDynamicData>{}
            : Map<String, _PlayerDynamicData>.from(_playerDynamicById);

    final Object? rawSelfPlayer = state['selfPlayer'];
    if (rawSelfPlayer is Map) {
      final Map<String, dynamic> selfPlayer = _mapFromDynamic(rawSelfPlayer);
      final String selfId = (selfPlayer['id'] as String? ?? '').trim();
      if (selfId.isNotEmpty) {
        nextDynamicById[selfId] = _dynamicPlayerFromJson(selfPlayer);
      }
    }

    if (state.containsKey('otherPlayers')) {
      final String currentPlayerId = (playerId ?? '').trim();
      if (currentPlayerId.isNotEmpty) {
        nextDynamicById.removeWhere(
          (String id, _PlayerDynamicData _) => id != currentPlayerId,
        );
      }

      final List<dynamic> rawOtherPlayers =
          state['otherPlayers'] as List<dynamic>? ?? [];
      for (final Map rawPlayer in rawOtherPlayers.whereType<Map>()) {
        final Map<String, dynamic> parsedPlayer = _mapFromDynamic(rawPlayer);
        final String id = (parsedPlayer['id'] as String? ?? '').trim();
        if (id.isEmpty) {
          continue;
        }
        nextDynamicById[id] = _dynamicPlayerFromJson(parsedPlayer);
      }
    } else if (state.containsKey('players')) {
      nextDynamicById
        ..clear()
        ..addAll(
          <String, _PlayerDynamicData>{
            for (final Map rawPlayer
                in (state['players'] as List<dynamic>? ?? const <dynamic>[])
                    .whereType<Map>())
              (_mapFromDynamic(rawPlayer)['id'] as String? ?? '').trim():
                  _dynamicPlayerFromJson(_mapFromDynamic(rawPlayer)),
          }..remove(''),
        );
    }

    _playerDynamicById = nextDynamicById;

    if (state.containsKey('gems')) {
      gems = _parseGems(state['gems'] as List<dynamic>?);
    }

    _rebuildPlayers();

    final List<dynamic> rawLayerTransforms =
        state['layerTransforms'] as List<dynamic>? ?? [];
    layerTransforms = rawLayerTransforms
        .whereType<Map>()
        .map(
          (Map transform) =>
              TransformSnapshot.fromJson(_mapFromDynamic(transform)),
        )
        .toList(growable: false);

    final List<dynamic> rawZoneTransforms =
        state['zoneTransforms'] as List<dynamic>? ?? [];
    zoneTransforms = rawZoneTransforms
        .whereType<Map>()
        .map(
          (Map transform) =>
              TransformSnapshot.fromJson(_mapFromDynamic(transform)),
        )
        .toList(growable: false);
  }

  _PlayerStaticData _staticPlayerFromJson(Map<String, dynamic> json) {
    return _PlayerStaticData(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? 'Player').trim(),
      width: (json['width'] as num? ?? 20).toDouble(),
      height: (json['height'] as num? ?? 20).toDouble(),
      joinOrder: (json['joinOrder'] as num? ?? 0).toInt(),
    );
  }

  _PlayerDynamicData _dynamicPlayerFromJson(Map<String, dynamic> json) {
    return _PlayerDynamicData(
      id: (json['id'] as String? ?? '').trim(),
      x: (json['x'] as num? ?? 0).toDouble(),
      y: (json['y'] as num? ?? 0).toDouble(),
      score: (json['score'] as num? ?? 0).toInt(),
      gemsCollected: (json['gemsCollected'] as num? ?? 0).toInt(),
      direction: (json['direction'] as String? ?? 'none').trim(),
      facing: (json['facing'] as String? ?? 'down').trim(),
      moving: json['moving'] as bool? ?? false,
      velocityY: (json['velocityY'] as num? ?? 0).toDouble(),
      onGround: json['onGround'] as bool? ?? true,
      winStage: (json['winStage'] as String? ?? 'none').trim(),
    );
  }

  void _rebuildPlayers() {
    final Set<String> ids = <String>{
      ..._playerStaticById.keys,
      ..._playerDynamicById.keys,
    };
    final List<MultiplayerPlayer> basePlayers = ids
        .map((String id) {
          final _PlayerStaticData? staticData = _playerStaticById[id];
          final _PlayerDynamicData? dynamicData = _playerDynamicById[id];
          return MultiplayerPlayer(
            id: id,
            name: staticData?.name ?? 'Player',
            x: dynamicData?.x ?? 0,
            y: dynamicData?.y ?? 0,
            width: staticData?.width ?? 20,
            height: staticData?.height ?? 20,
            score: dynamicData?.score ?? 0,
            gemsCollected: dynamicData?.gemsCollected ?? 0,
            direction: dynamicData?.direction ?? 'none',
            facing: dynamicData?.facing ?? 'down',
            moving: dynamicData?.moving ?? false,
            velocityY: dynamicData?.velocityY ?? 0,
            onGround: dynamicData?.onGround ?? true,
            joinOrder: staticData?.joinOrder ?? 0,
            winStage: dynamicData?.winStage ?? 'none',
          );
        })
        .toList(growable: false);

    players = _applyLocalBots(basePlayers);
  }

  List<MultiplayerPlayer> _applyLocalBots(List<MultiplayerPlayer> basePlayers) {
    if (!_shouldUseLocalBots) {
      return basePlayers;
    }

    final int targetCount = math.min(
      math.max(minPlayers, _minimumPlayersRequired),
      maxPlayers,
    );

    if (kDebugMode) {
      print(
        '[BOTS] Mode=LOCAL | Base players=${basePlayers.length} | Target=$targetCount | Min=$minPlayers | Max=$maxPlayers',
      );
    }

    if (basePlayers.length >= targetCount) {
      if (kDebugMode) {
        print(
          '[BOTS] No es necessari injectar bots (ja tenim $targetCount jugadors)',
        );
      }
      return basePlayers;
    }

    final List<MultiplayerPlayer> expanded = List<MultiplayerPlayer>.from(
      basePlayers,
    );
    final Set<String> usedIds = expanded
        .map((MultiplayerPlayer p) => p.id)
        .toSet();
    final String currentLocalId = (playerId ?? '').trim();
    MultiplayerPlayer? local;
    if (currentLocalId.isNotEmpty) {
      for (final MultiplayerPlayer player in basePlayers) {
        if (player.id == currentLocalId) {
          local = player;
          break;
        }
      }
    }
    final double baseX = local?.x ?? 120;
    final double baseY = local?.y ?? 120;
    int joinOrder = expanded.length;

    int botsAdded = 0;
    for (final _LocalBotProfile bot in _localBotPool) {
      if (expanded.length >= targetCount) {
        break;
      }
      if (usedIds.contains(bot.id)) {
        continue;
      }
      final int slot = expanded.length;
      expanded.add(
        MultiplayerPlayer(
          id: bot.id,
          name: bot.name,
          x: baseX + 40.0 * (slot % 3),
          y: baseY + 32.0 * (slot ~/ 3),
          width: local?.width ?? 20,
          height: local?.height ?? 20,
          score: 0,
          gemsCollected: 0,
          direction: 'none',
          facing: 'down',
          moving: false,
          velocityY: 0,
          onGround: true,
          joinOrder: 1000 + joinOrder,
        ),
      );
      usedIds.add(bot.id);
      botsAdded++;
      if (kDebugMode) {
        print(
          '[BOTS] Injectat ${bot.name} (${bot.id}) | Jugadors totals=${expanded.length}',
        );
      }
      joinOrder++;
    }
    if (kDebugMode) {
      print(
        '[BOTS] Injecció completada: $botsAdded bots afegits | Jugadors finals=${expanded.length}',
      );
    }
    return expanded;
  }

  List<MultiplayerGem> _parseGems(List<dynamic>? rawGems) {
    return (rawGems ?? const <dynamic>[])
        .whereType<Map>()
        .map((Map gem) => MultiplayerGem.fromJson(_mapFromDynamic(gem)))
        .toList(growable: false);
  }

  void _registerPlayer() {
    if (_registrationSent) {
      return;
    }
    _registrationSent = true;

    final String safeName = playerName.trim().isEmpty
        ? 'Player'
        : playerName.trim();
    roomCode = 'GLOBAL';

    _sendMessage(<String, dynamic>{'type': 'register', 'playerName': safeName});
  }

  void _onWebSocketError(dynamic error) {
    if (kDebugMode) {
      print('Error de WebSocket: $error');
    }
    _resetConnectionState();
    _scheduleReconnect();
  }

  void _onWebSocketClosed() {
    // If the server closed with the kick code, treat it as permanent.
    final int? closeCode = _wsHandler.lastCloseCode;
    if (closeCode == kKickCloseCode) {
      if (kDebugMode) {
        print('WebSocket tancat per kick del servidor (codi $closeCode). No es reconnecta.');
      }
      _wasKicked = true;
      _intentionalDisconnect = true;
      _resetConnectionState();
      return;
    }
    if (kDebugMode) {
      print('WebSocket tancat (codi $closeCode). Intentant reconnectar...');
    }
    _resetConnectionState();
    _scheduleReconnect();
  }

  // Cleans up all in-session state when the connection drops (intentional or not).
  // Called on both error and clean close so the UI never shows stale data.
  void _resetConnectionState() {
    isConnected = false;
    isConnecting = false;
    phase = MatchPhase.connecting;
    roomStatus = 'connecting';
    roomErrorMessage = null;
    players = const <MultiplayerPlayer>[];
    gems = const <MultiplayerGem>[];
    matchKey = null;
    _playerStaticById = const <String, _PlayerStaticData>{};
    _playerDynamicById = const <String, _PlayerDynamicData>{};
    _registrationSent = false;
    _lastDirection = 'none';
    notifyListeners();
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect || _wasKicked || _disposed) {
      return;
    }
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print(
          "No es pot reconnectar al servidor després de $_maxReconnectAttempts intents.",
        );
      }
      return;
    }

    _reconnectAttempts++;
    if (kDebugMode) {
      print(
        "Intent de reconnexió #$_reconnectAttempts en ${_reconnectDelay.inSeconds} segons...",
      );
    }
    Future<void>.delayed(_reconnectDelay, () {
      if (_intentionalDisconnect || _disposed) {
        return;
      }
      _connectToWebSocket();
    });
  }

  void _sendMessage(Map<String, dynamic> payload) {
    if (_intentionalDisconnect ||
        _wsHandler.connectionStatus != ConnectionStatus.connected) {
      return;
    }
    _wsHandler.sendMessage(jsonEncode(payload));
  }

  MatchPhase _parsePhase(String? rawPhase) {
    switch ((rawPhase ?? '').trim().toLowerCase()) {
      case 'waiting':
        return MatchPhase.waiting;
      case 'playing':
        return MatchPhase.playing;
      case 'finished':
        return MatchPhase.finished;
      case 'connecting':
      default:
        return MatchPhase.connecting;
    }
  }

  String _normalizeDirection(String rawDirection) {
    switch (rawDirection.trim()) {
      case 'up':
      case 'upLeft':
      case 'left':
      case 'downLeft':
      case 'down':
      case 'downRight':
      case 'right':
      case 'upRight':
      case 'none':
        return rawDirection.trim();
      default:
        return 'none';
    }
  }

  Map<String, dynamic> _mapFromDynamic(Map<dynamic, dynamic> raw) {
    return raw.map(
      (dynamic key, dynamic value) => MapEntry(key.toString(), value),
    );
  }
}
