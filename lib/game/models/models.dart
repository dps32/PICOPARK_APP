/**
 * Game Models
 * Modelos de datos del juego siguiendo SOLID principles
 */

import 'enums.dart';

/// Representa un jugador en el juego
class Player {
  final String id;
  final String name;
  double x;
  double y;
  final double width;
  final double height;
  String direction;
  String facing;
  bool moving;
  int score;
  int gemsCollected;
  final int joinOrder;
  final bool isHost;
  final bool isBot;

  Player({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.direction,
    required this.facing,
    required this.moving,
    required this.score,
    required this.gemsCollected,
    required this.joinOrder,
    required this.isHost,
    required this.isBot,
  });

  /// Crear Player desde JSON (para serialización)
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] ?? json['nickname'] ?? 'Player') as String,
      x: (json['x'] as num? ?? 0).toDouble(),
      y: (json['y'] as num? ?? 0).toDouble(),
      width: (json['width'] as num? ?? 20).toDouble(),
      height: (json['height'] as num? ?? 20).toDouble(),
      direction: (json['direction'] as String? ?? 'none').trim(),
      facing: (json['facing'] as String? ?? 'down').trim(),
      moving: json['moving'] as bool? ?? false,
      score: (json['score'] as num? ?? 0).toInt(),
      gemsCollected: (json['gemsCollected'] as num? ?? 0).toInt(),
      joinOrder: (json['joinOrder'] as num? ?? 0).toInt(),
      isHost: json['isHost'] as bool? ?? false,
      isBot: (json['id'] as String? ?? '').contains('bot_'),
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'direction': direction,
        'facing': facing,
        'moving': moving,
        'score': score,
        'gemsCollected': gemsCollected,
        'joinOrder': joinOrder,
        'isHost': isHost,
      };

  /// Copiar con cambios
  Player copyWith({
    double? x,
    double? y,
    String? direction,
    String? facing,
    bool? moving,
    int? score,
    int? gemsCollected,
  }) {
    return Player(
      id: id,
      name: name,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width,
      height: height,
      direction: direction ?? this.direction,
      facing: facing ?? this.facing,
      moving: moving ?? this.moving,
      score: score ?? this.score,
      gemsCollected: gemsCollected ?? this.gemsCollected,
      joinOrder: joinOrder,
      isHost: isHost,
      isBot: isBot,
    );
  }
}

/// Representa una sala/room del juego
class Room {
  final String id;
  String code;
  final String hostId;
  RoomStatus status;
  final List<Player> players;
  final int minPlayers;
  final int maxPlayers;
  final int createdAt;
  int? startedAt;
  int? finishedAt;
  final String levelName;
  int remainingGems;
  int countdownSeconds;

  Room({
    required this.id,
    required this.code,
    required this.hostId,
    required this.status,
    required this.players,
    required this.minPlayers,
    required this.maxPlayers,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    required this.levelName,
    required this.remainingGems,
    required this.countdownSeconds,
  });

  /// Crear Room desde JSON
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: (json['id'] as String? ?? '').trim(),
      code: (json['code'] as String? ?? '').trim(),
      hostId: (json['hostSocketId'] as String? ?? json['hostId'] as String? ?? '').trim(),
      status: _parseRoomStatus((json['status'] as String? ?? 'lobby').trim()),
      players: (json['players'] as List<dynamic>? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((p) => Player.fromJson(p.cast<String, dynamic>()))
          .toList(),
      minPlayers: (json['minPlayers'] as num? ?? 3).toInt(),
      maxPlayers: (json['maxPlayers'] as num? ?? 8).toInt(),
      createdAt: (json['createdAt'] as num? ?? DateTime.now().millisecondsSinceEpoch).toInt(),
      startedAt: (json['startedAt'] as num?)?.toInt(),
      finishedAt: (json['finishedAt'] as num?)?.toInt(),
      levelName: (json['levelName'] as String? ?? 'All together now').trim(),
      remainingGems: (json['remainingGems'] as num? ?? 0).toInt(),
      countdownSeconds: (json['countdownSeconds'] as num? ?? 0).toInt(),
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'hostSocketId': hostId,
        'status': status.toString().split('.').last,
        'players': players.map((p) => p.toJson()).toList(),
        'minPlayers': minPlayers,
        'maxPlayers': maxPlayers,
        'levelName': levelName,
        'remainingGems': remainingGems,
        'countdownSeconds': countdownSeconds,
      };

  static RoomStatus _parseRoomStatus(String status) {
    switch (status.toLowerCase()) {
      case 'playing':
      case 'in_game':
        return RoomStatus.playing;
      case 'finished':
        return RoomStatus.finished;
      default:
        return RoomStatus.lobby;
    }
  }
}

/// Estado general del juego
class GameState {
  final MatchPhase phase;
  final Room? room;
  final List<Player> players;
  final String? localPlayerId;
  final int countdownSeconds;
  final String? errorMessage;

  GameState({
    required this.phase,
    this.room,
    this.players = const [],
    this.localPlayerId,
    this.countdownSeconds = 0,
    this.errorMessage,
  });

  /// Obtener jugador local
  Player? getLocalPlayer() {
    if (localPlayerId == null) return null;
    try {
      return players.firstWhere((p) => p.id == localPlayerId);
    } catch (_) {
      return null;
    }
  }

  /// Copiar con cambios
  GameState copyWith({
    MatchPhase? phase,
    Room? room,
    List<Player>? players,
    String? localPlayerId,
    int? countdownSeconds,
    String? errorMessage,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      room: room ?? this.room,
      players: players ?? this.players,
      localPlayerId: localPlayerId ?? this.localPlayerId,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'GameState(phase=$phase, room=${room?.code}, players=${players.length}, localPlayer=$localPlayerId)';
}
