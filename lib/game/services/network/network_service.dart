/**
 * Network Service Interface
 * Define el contrato que todos los servicios de red deben cumplir
 * Permite Dependency Inversion (SOLID)
 */

import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// DTO para mensajes de red
class NetworkMessage {
  final String type;
  final Map<String, dynamic> payload;

  NetworkMessage({
    required this.type,
    required this.payload,
  });

  factory NetworkMessage.fromJson(Map<String, dynamic> json) {
    return NetworkMessage(
      type: (json['type'] as String? ?? '').trim(),
      payload: json['payload'] as Map<String, dynamic>? ?? json,
    );
  }

  @override
  String toString() => 'NetworkMessage(type=$type, payload=$payload)';
}

/// Interfaz para servicios de red
/// Implementada por: LocalNetworkService, RemoteNetworkService
abstract class INetworkService {
  /// Conectar con el servidor/modo
  Future<void> connect(String playerName, String? roomCode);

  /// Desconectar
  Future<void> disconnect();

  /// Enviar mensaje al servidor
  void sendMessage(String type, Map<String, dynamic> payload);

  /// Stream de mensajes recibidos
  Stream<NetworkMessage> get messagesStream;

  /// Obtener conexión actual
  bool get isConnected;

  /// Obtener ID del cliente
  String? get clientId;
}
