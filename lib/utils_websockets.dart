import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus { disconnected, disconnecting, connecting, connected }

// WebSocket close code sent by the server when kicking a player intentionally.
// Codes 4000-4999 are reserved for application use by the WS spec.
const int kKickCloseCode = 4001;

// How often the client sends an application-level ping to keep the server's
// inactivity timer alive (must be < server INACTIVITY_TIMEOUT_MS of 60s).
const Duration _kHeartbeatInterval = Duration(seconds: 20);

class WebSocketsHandler {
  late Function _callback;
  String host = 'localhost';
  String port = '8888';
  String? socketId;

  WebSocketChannel? _socketClient;
  ConnectionStatus connectionStatus = ConnectionStatus.disconnected;
  Timer? _heartbeatTimer;

  // Last close code received from the server (null if not a clean close).
  int? lastCloseCode;

  void connectToServer(
    String serverHost,
    int serverPort,
    void Function(String message) callback, {
    bool useSecureSocket = false,
    void Function(dynamic error)? onError,
    void Function()? onDone,
  }) {
    // Silently close any existing socket before opening a new one.
    // This prevents duplicate connections when retries overlap.
    if (connectionStatus != ConnectionStatus.disconnected) {
      _stopHeartbeat();
      _socketClient?.sink.close();
      _socketClient = null;
      connectionStatus = ConnectionStatus.disconnected;
    }

    _callback = callback;
    host = serverHost;
    port = serverPort.toString();
    lastCloseCode = null;
    connectionStatus = ConnectionStatus.connecting;

    try {
      final Uri uri = Uri(
        scheme: useSecureSocket ? 'wss' : 'ws',
        host: host,
        port: serverPort,
      );
      final WebSocketChannel socket = WebSocketChannel.connect(uri);
      _socketClient = socket;
      connectionStatus = ConnectionStatus.connected;

      _startHeartbeat();

      socket.stream.listen(
        (message) {
          // Discard messages from a stale socket replaced by a newer connection.
          if (!identical(_socketClient, socket)) return;
          _handleMessage(message);
          _callback(message);
        },
        onError: (error) {
          if (!identical(_socketClient, socket)) return;
          _stopHeartbeat();
          connectionStatus = ConnectionStatus.disconnected;
          onError?.call(error);
        },
        onDone: () {
          if (!identical(_socketClient, socket)) return;
          _stopHeartbeat();
          lastCloseCode = socket.closeCode;
          connectionStatus = ConnectionStatus.disconnected;
          onDone?.call();
        },
      );
    } catch (e) {
      _stopHeartbeat();
      connectionStatus = ConnectionStatus.disconnected;
      onError?.call(e);
    }
  }

  void _handleMessage(String message) {
    try {
      final Object? decoded = jsonDecode(message);
      if (decoded is Map) {
        final Map<String, dynamic> data = decoded.map(
          (dynamic key, dynamic value) => MapEntry(key.toString(), value),
        );
        final String type = (data['type'] as String? ?? '').trim();
        final Object? payload = data['payload'];
        final Map<String, dynamic> body = payload is Map
            ? payload.map(
                (dynamic key, dynamic value) =>
                    MapEntry(key.toString(), value),
              )
            : data;

        if ((type == 'welcome' || type == 'server:connected') &&
            (body['id'] != null || body['socketId'] != null)) {
          socketId =
              (body['socketId'] as String? ?? body['id'] as String? ?? '')
                  .trim();
          if (kDebugMode) {
            print('Client ID assignat pel servidor: $socketId');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processant missatge WebSocket: $e');
      }
    }
  }

  void sendMessage(String message) {
    if (connectionStatus == ConnectionStatus.connected) {
      _socketClient!.sink.add(message);
    }
  }

  void disconnectFromServer() {
    _stopHeartbeat();
    connectionStatus = ConnectionStatus.disconnecting;
    _socketClient?.sink.close();
    connectionStatus = ConnectionStatus.disconnected;
  }

  // Sends a JSON ping every interval so the server's inactivity monitor
  // keeps the player's lastActivityAt fresh while in the waiting room.
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_kHeartbeatInterval, (_) {
      if (connectionStatus == ConnectionStatus.connected) {
        sendMessage(jsonEncode({'type': 'ping'}));
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}
