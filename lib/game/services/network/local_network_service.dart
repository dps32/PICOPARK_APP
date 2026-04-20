/**
 * Local Network Service
 * Implementación de INetworkService para modo local (sin servidor)
 * Simula un servidor en memoria
 */

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'network_service.dart';
import '../models/models.dart';
import '../models/enums.dart';

class LocalNetworkService implements INetworkService {
  final StreamController<NetworkMessage> _messageController =
      StreamController<NetworkMessage>.broadcast();

  late String _clientId;
  late String _playerName;
  String? _roomCode;
  bool _isConnected = false;

  // Simulación de servidor local
  late Room _simulatedRoom;
  final List<Player> _simulatedPlayers = [];

  @override
  bool get isConnected => _isConnected;

  @override
  String? get clientId => _clientId;

  @override
  Stream<NetworkMessage> get messagesStream => _messageController.stream;

  @override
  Future<void> connect(String playerName, String? roomCode) async {
    if (kDebugMode) {
      print('[LOCAL] Iniciando conexión en modo local...');
    }

    _clientId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    _playerName = playerName;
    _roomCode = roomCode ?? _generateRoomCode();

    // Enviar welcome message
    _messageController.add(NetworkMessage(
      type: 'welcome',
      payload: {
        'id': _clientId,
        'minPlayers': GameConfig.minPlayers,
        'maxPlayers': GameConfig.maxPlayers,
      },
    ));

    // Simular registro
    await _simulateRegister();

    _isConnected = true;

    if (kDebugMode) {
      print('[LOCAL] ✓ Conectado | ID: $_clientId | Room: $_roomCode');
    }
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    _messageController.close();
    if (kDebugMode) {
      print('[LOCAL] Desconectado');
    }
  }

  @override
  void sendMessage(String type, Map<String, dynamic> payload) {
    if (!_isConnected) return;

    if (kDebugMode) {
      print('[LOCAL] Mensaje enviado: $type');
    }

    // Procesar mensajes localmente
    switch (type) {
      case 'register':
      case 'room:join':
      case 'room:create':
        _handleRegisterMessage(payload);
        break;
      case 'direction':
        _handleMovementMessage(payload);
        break;
      case 'startMatch':
      case 'room:start':
        _handleStartMatch();
        break;
    }
  }

  /// Simular registro del jugador
  Future<void> _simulateRegister() async {
    // Crear jugador local
    final localPlayer = Player(
      id: _clientId,
      name: _playerName,
      x: 100,
      y: 100,
      width: 20,
      height: 20,
      direction: 'none',
      facing: 'down',
      moving: false,
      score: 0,
      gemsCollected: 0,
      joinOrder: 0,
      isHost: true,
      isBot: false,
    );

    _simulatedPlayers.add(localPlayer);

    // Crear sala local
    _simulatedRoom = Room(
      id: 'local_room_${DateTime.now().millisecondsSinceEpoch}',
      code: _roomCode!,
      hostId: _clientId,
      status: RoomStatus.lobby,
      players: [..._simulatedPlayers],
      minPlayers: GameConfig.minPlayers,
      maxPlayers: GameConfig.maxPlayers,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      levelName: 'All together now',
      remainingGems: 0,
      countdownSeconds: 0,
    );

    // Inyectar bots
    _injectBots();

    // Enviar confirmación de unión
    _messageController.add(NetworkMessage(
      type: 'room:joined',
      payload: {
        'roomCode': _simulatedRoom.code,
        'roomId': _simulatedRoom.id,
        'isHost': true,
        'players': _simulatedPlayers.map((p) => p.toJson()).toList(),
      },
    ));

    // Enviar actualización de sala
    _broadcastRoomUpdate();
  }

  /// Inyectar bots para alcanzar mínimo de jugadores
  void _injectBots() {
    const botNames = ['Bot Kiwi', 'Bot Mango'];
    int botsToAdd = 2; // Exactamente 2 bots (1 jugador + 2 bots = 3 total)

    for (int i = 0; i < botsToAdd; i++) {
      final bot = Player(
        id: 'bot_local_${i + 1}',
        name: botNames[i],
        x: 100 + ((i + 1) * 40),
        y: 100 + ((i + 1) * 32),
        width: 20,
        height: 20,
        direction: 'none',
        facing: 'down',
        moving: false,
        score: 0,
        gemsCollected: 0,
        joinOrder: _simulatedPlayers.length,
        isHost: false,
        isBot: true,
      );

      _simulatedPlayers.add(bot);

      if (kDebugMode) {
        print('[BOTS] ✓ ${bot.name} inyectado (ID: ${bot.id}) | Posición: (${bot.x}, ${bot.y})');
      }
    }

    if (kDebugMode) {
      print('[BOTS] ✓ Inyección completada | Total jugadores: ${_simulatedPlayers.length}');
      print('[BOTS] → Jugador local + 2 bots (SIN MOVIMIENTO)');
    }
  }

  /// Procesar mensaje de registro
  void _handleRegisterMessage(Map<String, dynamic> payload) {
    if (kDebugMode) {
      print('[LOCAL] Mensaje de registro: $payload');
    }
  }

  /// Procesar movimiento del jugador LOCAL
  /// LOS BOTS NO SE MUEVEN (no tienen IA)
  void _handleMovementMessage(Map<String, dynamic> payload) {
    final direction = (payload['value'] as String? ?? 'none').trim();

    // Buscar y actualizar SOLO el jugador local
    final localPlayerIndex =
        _simulatedPlayers.indexWhere((p) => p.id == _clientId);
    if (localPlayerIndex == -1) {
      return; // Jugador local no encontrado
    }

    final player = _simulatedPlayers[localPlayerIndex];
    const speed = 2.0;

    // Actualizar posición del jugador local
    switch (direction) {
      case 'left':
        player.x = max(0, player.x - speed);
        player.facing = 'left';
        break;
      case 'right':
        player.x = min(GameConfig.worldWidth - player.width, player.x + speed);
        player.facing = 'right';
        break;
      case 'up':
        player.y = max(0, player.y - speed);
        break;
      case 'down':
        player.y = min(GameConfig.worldHeight - player.height, player.y + speed);
        break;
      default:
        break;
    }

    player.direction = direction;
    player.moving = direction != 'none';

    if (kDebugMode && direction != 'none') {
      print('[LOCAL] Jugador ${player.name} movido a (${player.x}, ${player.y})');
    }

    // Broadcast movimiento solo del jugador local
    _messageController.add(NetworkMessage(
      type: 'player:moved',
      payload: {
        'playerId': _clientId,
        'x': player.x,
        'y': player.y,
        'direction': player.direction,
        'facing': player.facing,
      },
    ));
  }

  /// Iniciar partida
  void _handleStartMatch() {
    if (_simulatedRoom.players.length < GameConfig.minPlayers) {
      if (kDebugMode) {
        print('[LOCAL] ✗ No hay suficientes jugadores para comenzar');
      }
      return;
    }

    _simulatedRoom.status = RoomStatus.playing;
    _simulatedRoom.startedAt = DateTime.now().millisecondsSinceEpoch;

    if (kDebugMode) {
      print('[LOCAL] ✓ Partida iniciada con ${_simulatedRoom.players.length} jugadores');
    }

    _messageController.add(NetworkMessage(
      type: 'room:started',
      payload: {
        'status': 'playing',
        'startTime': _simulatedRoom.startedAt,
      },
    ));
  }

  /// Broadcast de actualización de sala
  void _broadcastRoomUpdate() {
    _messageController.add(NetworkMessage(
      type: 'room:update',
      payload: {
        'roomCode': _simulatedRoom.code,
        'status': _simulatedRoom.status.toString().split('.').last,
        'hostSocketId': _simulatedRoom.hostId,
        'players': _simulatedRoom.players.map((p) => p.toJson()).toList(),
        'minPlayers': _simulatedRoom.minPlayers,
        'maxPlayers': _simulatedRoom.maxPlayers,
      },
    ));
  }

  /// Generar código de sala aleatorio
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    for (int i = 0; i < 4; i++) {
      code += chars[Random().nextInt(chars.length)];
    }
    return code;
  }
}
