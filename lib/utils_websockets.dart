import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus { disconnected, disconnecting, connecting, connected }

class WebSocketsHandler {
  late Function _callback;
  String host = "localhost";
  String port = "8888";
  String? socketId;

  WebSocketChannel? _socketClient;
  ConnectionStatus connectionStatus = ConnectionStatus.disconnected;

  void connectToServer(
    String serverHost,
    int serverPort,
    void Function(String message) callback, {
    bool useSecureSocket = false,
    void Function(dynamic error)? onError,
    void Function()? onDone,
  }) async {
    _callback = callback;
    host = serverHost;
    port = serverPort.toString();

    connectionStatus = ConnectionStatus.connecting;

    try {
      final Uri uri = Uri(
        scheme: useSecureSocket ? 'wss' : 'ws',
        host: host,
        port: serverPort,
      );
      _socketClient = WebSocketChannel.connect(uri);
      connectionStatus = ConnectionStatus.connected;

      _socketClient!.stream.listen(
        (message) {
          _handleMessage(message);
          _callback(message);
        },
        onError: (error) {
          connectionStatus = ConnectionStatus.disconnected;
          onError?.call(error);
        },
        onDone: () {
          connectionStatus = ConnectionStatus.disconnected;
          onDone?.call();
        },
      );
    } catch (e) {
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
              (body['socketId'] as String? ?? body['id'] as String? ?? '').trim();
          if (kDebugMode) {
            print('Client ID assignat pel servidor: $socketId');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error processant missatge WebSocket: $e");
      }
    }
  }

  void sendMessage(String message) {
    if (connectionStatus == ConnectionStatus.connected) {
      _socketClient!.sink.add(message);
    }
  }

  void disconnectFromServer() {
    connectionStatus = ConnectionStatus.disconnecting;
    _socketClient?.sink.close();
    connectionStatus = ConnectionStatus.disconnected;
  }
}
