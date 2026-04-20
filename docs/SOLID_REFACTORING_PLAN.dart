/// REFACTORIZACIÓN DEL CLIENTE FLUTTER - PRINCIPIOS SOLID
/// 
/// CAMBIOS PLANEADOS:
/// 
/// ======================== ANTES (Anti-pattern) ========================
/// 
/// AppData (monolito)
/// ├── WebSocket connection
/// ├── Game state management
/// ├── Player logic
/// ├── Room management
/// ├── Movement updates
/// └── Serialization logic
/// 
/// Problemas: 
/// - 1 clase = N responsabilidades (violación de SRP)
/// - Difícil de testear
/// - Difícil de reutilizar
/// - Difícil de expandir
/// 
/// 
/// ======================== DESPUÉS (SOLID) ========================
/// 
/// game/
/// ├── services/
/// │   ├── network/
/// │   │   ├── network_service.dart       (Interfaz)
/// │   │   ├── remote_network_service.dart (Implementación remota)
/// │   │   ├── local_network_service.dart  (Implementación local)
/// │   │   └── network_message.dart        (DTOs)
/// │   ├── game_state_service.dart        (Gestiona estado)
/// │   ├── room_service.dart              (Gestiona salas)
/// │   └── player_service.dart            (Gestiona jugadores)
/// ├── models/
/// │   ├── player.dart
/// │   ├── room.dart
/// │   ├── game_state.dart
/// │   └── enums.dart
/// ├── screens/
/// │   ├── base_screen.dart               (Interfaz)
/// │   ├── waiting_room_screen.dart       (Ya refactorizado)
/// │   └── play_screen.dart
/// ├── app_controller.dart                (Orquesta servicios)
/// └── app_view.dart                      (UI)
/// 
/// Ventajas:
/// ✓ Cada clase tiene UNA responsabilidad
/// ✓ Fácil de testear (depender de interfaces)
/// ✓ Fácil de reutilizar (servicios independientes)
/// ✓ Fácil de expandir (agregar nuevos servicios)
/// ✓ Fácil de demostrar (código limpio y documentado)
/// 
/// 
/// ======================== MAPEO DE MIGRACIÓN ========================
/// 
/// AppData.isConnected
///   → GameStateService.gamePhase
/// 
/// AppData.players
///   → RoomService.room.players
/// 
/// AppData._connectToWebSocket()
///   → NetworkService.connect()
/// 
/// AppData.updateMovementDirection()
///   → PlayerService.updateDirection() + NetworkService.sendMessage()
/// 
/// AppData.requestMatchStart()
///   → RoomService.startMatch() + NetworkService.sendMessage()
/// 
/// 
/// ======================== INTERFACES CLAVE ========================
/// 
/// INetworkService (Dependency Inversion)
/// - connect(config)
/// - disconnect()
/// - sendMessage(type, payload)
/// - onMessageReceived() → Stream
/// 
/// IGameStateService
/// - updatePhase(MatchPhase)
/// - updateCountdown(int)
/// - getGameState() → GameState
/// 
/// IRoomService
/// - joinRoom(code)
/// - startRoom()
/// - getRoomInfo() → Room
/// 
/// IPlayerService
/// - getLocalPlayer() → Player
/// - updatePlayerMovement(direction)
/// - getAllPlayers() → List<Player>
/// 
/// 
/// ======================== SECUENCIA DE IMPLEMENTACIÓN ========================
/// 
/// Día 1-2: Crear interfaces y modelos
/// - types y enums
/// - DTOs (Data Transfer Objects)
/// - interfaces de servicios
/// 
/// Día 3-4: Implementar servicios
/// - LocalNetworkService (para modo local)
/// - RemoteNetworkService (para modo remoto)
/// - GameStateService
/// - RoomService
/// - PlayerService
/// 
/// Día 5: Migrar AppData → AppController
/// - Usar servicios inyectados
/// - Mantener compatibilidad con UI existente
/// 
/// Día 6: Refactorizar screens
/// - Usar AppController en lugar de AppData
/// - Screens implementan interfaz base
/// 
/// Día 7: Testing + Demo
/// - Tests unitarios para servicios
/// - Demo del sprint
/// 
/// 
/// ======================== BENEFICIOS ========================
/// 
/// Para Desarrollo:
/// - Código más legible (cada clase = 1 cosa)
/// - Más fácil de debuggear (responsabilidades claras)
/// - Más fácil de testear (interfaces permiten mocks)
/// - Menos coupling (servicios independientes)
/// - Más fácil de escalar (agregar features sin romper)
/// 
/// Para Demostraciones Semanales:
/// - Código limpio = fácil explicar progreso
/// - Interfaces claras = fácil mostrar arquitectura
/// - Servicios separados = fácil mostrar modo local vs remoto
/// - DTOs = fácil entender flujo de datos
/// - Tests = fácil probar funcionalidad
library;

// EJEMPLO: Cómo se vería el código refactorizado

// ===== INTERFACES =====

abstract class INetworkService {
  Future<void> connect(NetworkConfig config);
  Future<void> disconnect();
  void sendMessage(String type, Map<String, dynamic> payload);
  Stream<NetworkMessage> get messagesStream;
}

abstract class IGameStateService {
  void updatePhase(MatchPhase phase);
  void updateCountdown(int seconds);
  GameState getGameState();
  Stream<GameState> get stateChanges;
}

// ===== MODELOS =====

class Player {
  final String id;
  final String name;
  final double x;
  final double y;
  final bool isLocal;
  final bool isBot;

  Player({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.isLocal,
    required this.isBot,
  });
}

class Room {
  final String id;
  final String code;
  final List<Player> players;
  final String hostId;
  final RoomStatus status;

  Room({
    required this.id,
    required this.code,
    required this.players,
    required this.hostId,
    required this.status,
  });
}

enum RoomStatus { lobby, playing, finished }
enum MatchPhase { connecting, waiting, playing, finished }

// ===== SERVICIOS =====

class LocalNetworkService implements INetworkService {
  // Modo local: simula servidor sin conexión real
  
  @override
  Future<void> connect(NetworkConfig config) async {
    // Inicializa modo local
    debugPrint('[LOCAL] Conectando en modo local...');
  }

  @override
  void sendMessage(String type, Map<String, dynamic> payload) {
    // Procesa mensajes localmente
    debugPrint('[LOCAL] Mensaje: $type -> $payload');
  }
}

class RemoteNetworkService implements INetworkService {
  // Modo remoto: conecta con servidor real
  final WebSocketsHandler _wsHandler = WebSocketsHandler();

  @override
  Future<void> connect(NetworkConfig config) async {
    // Conecta con servidor remoto
    debugPrint('[REMOTE] Conectando a ${config.serverHost}:${config.serverPort}');
  }

  @override
  void sendMessage(String type, Map<String, dynamic> payload) {
    // Envía al servidor
    _wsHandler.send('{"type":"$type","payload":$payload}');
  }
}

class GameStateService implements IGameStateService {
  final GameState _state = GameState();

  @override
  void updatePhase(MatchPhase phase) {
    _state.phase = phase;
    // Notificar cambios
  }

  @override
  GameState getGameState() => _state;
}

// ===== CONTROLADOR (reemplaza AppData) =====

class AppController extends ChangeNotifier {
  late final INetworkService _networkService;
  late final IGameStateService _gameStateService;
  late final RoomService _roomService;
  late final PlayerService _playerService;

  AppController({
    required NetworkConfig config,
  }) {
    // Inyectar dependencias según modo
    if (config.serverOption == ServerOption.local) {
      _networkService = LocalNetworkService();
    } else {
      _networkService = RemoteNetworkService();
    }

    _gameStateService = GameStateService();
    _roomService = RoomService(_networkService);
    _playerService = PlayerService(_networkService, _roomService);

    _initialize();
  }

  void _initialize() {
    // Orquestar conexión
    _networkService.messagesStream.listen((message) {
      _onMessage(message);
    });
  }

  void _onMessage(NetworkMessage message) {
    // Router de mensajes
    switch (message.type) {
      case 'welcome':
        _gameStateService.updatePhase(MatchPhase.waiting);
        break;
      case 'room:update':
        _roomService.updateRoom(message.payload);
        break;
      // ...
    }
    notifyListeners();
  }
}

// Notas:
// - Cada servicio tiene responsabilidad clara
// - UI depende de AppController, no de AppData
// - Fácil cambiar LocalNetworkService → RemoteNetworkService
// - Fácil agregar nuevos servicios (botService, physicsService, etc)
// - Fácil testear: inyectar mocks
// - Fácil demostrar: mostrar servicios separados
