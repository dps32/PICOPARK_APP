enum ServerOption { local, remote }

class NetworkConfig {
  static const String remoteServer = 'apalaci8.ieti.site';

  final ServerOption serverOption;
  final String playerName;
  final String roomCode;

  const NetworkConfig({
    required this.serverOption,
    required this.playerName,
    this.roomCode = '',
  });

  static const NetworkConfig defaults = NetworkConfig(
    serverOption: ServerOption.local,
    playerName: 'Player',
    roomCode: '',
  );

  String get serverHost {
    switch (serverOption) {
      case ServerOption.local:
        return '127.0.0.1';
      case ServerOption.remote:
        return remoteServer;
    }
  }

  int get serverPort {
    switch (serverOption) {
      case ServerOption.local:
        return 3000;
      case ServerOption.remote:
        return 443;
    }
  }

  bool get useSecureWebSocket {
    switch (serverOption) {
      case ServerOption.local:
        return false;
      case ServerOption.remote:
        return true;
    }
  }

  String get serverLabel {
    switch (serverOption) {
      case ServerOption.local:
        return 'Local (127.0.0.1:3000)';
      case ServerOption.remote:
        return 'Remote ($remoteServer:443)';
    }
  }

  NetworkConfig copyWith({
    ServerOption? serverOption,
    String? playerName,
    String? roomCode,
  }) {
    return NetworkConfig(
      serverOption: serverOption ?? this.serverOption,
      playerName: playerName ?? this.playerName,
      roomCode: roomCode ?? this.roomCode,
    );
  }
}
