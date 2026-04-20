/**
 * Game Enums and Constants
 * Valores compartidos en todo el juego
 */

enum MatchPhase { connecting, waiting, playing, finished }

enum RoomStatus { lobby, playing, finished }

enum ServerOption { local, remote }

enum Direction { left, right, up, down, none }

extension DirectionString on Direction {
  String toValue() {
    switch (this) {
      case Direction.left:
        return 'left';
      case Direction.right:
        return 'right';
      case Direction.up:
        return 'up';
      case Direction.down:
        return 'down';
      case Direction.none:
        return 'none';
    }
  }

  static Direction fromString(String value) {
    switch (value.toLowerCase()) {
      case 'left':
        return Direction.left;
      case 'right':
        return Direction.right;
      case 'up':
        return Direction.up;
      case 'down':
        return Direction.down;
      default:
        return Direction.none;
    }
  }
}

// Game constants
class GameConfig {
  static const int minPlayers = 3;
  static const int maxPlayers = 8;
  static const double worldWidth = 1280;
  static const double worldHeight = 720;
  static const int gameUpdateInterval = 16; // ~60 FPS
  static const int defaultCountdown = 60;
}

// Network constants
class NetworkConstants {
  static const String localHost = '127.0.0.1';
  static const int localPort = 3000;
  static const String remoteHost = 'play.picopark.io';
  static const int remotePort = 443;
  static const bool remoteSecure = true;
}
