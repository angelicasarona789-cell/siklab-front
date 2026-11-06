
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/user_session.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();

  factory SyncService() => _instance;

  SyncService._internal();

  io.Socket? _socket;
  bool _connected = false;

  void connect(int userId) {
    if (_socket != null && _connected) return;

    _socket?.disconnect();
    _connected = false;

    final socketUrl = ApiService.baseUrl();

    debugPrint('SyncService: Connecting to $socketUrl');

    _socket = io.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 2000,
      'timeout': 30000,
    });

    _socket!.onConnect((_) {
      debugPrint('SyncService: Connected successfully');

      _socket!.emit('join', {
        'user_id': userId,
      });

      _connected = true;
    });

    _socket!.onDisconnect((_) {
      debugPrint('SyncService: Disconnected');
      _connected = false;
    });

    _socket!.onError((e) {
      debugPrint('SyncService: Error - $e');
    });

    _socket!.onConnectError((e) {
      debugPrint('SyncService: Connection error - $e');
      _connected = false;
    });

    _socket!.on('sync_active_time', (data) {
      final seconds = data['total_seconds'] as int? ?? 0;

      debugPrint('Sync active time: $seconds seconds');

      UserSession().syncActiveTime(seconds);
    });

    _socket!.on('sync_progress', (data) {
      final language = data['language'] as String? ?? '';

      debugPrint('Sync progress: $language');

      ApiService.loadLanguageProgress();
    });

    _socket!.on('sync_profile', (data) {
      debugPrint('Sync profile received');

      UserSession().updateFromSync(
        Map<String, dynamic>.from(data),
      );
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();

    _socket = null;
    _connected = false;

    debugPrint('SyncService: Manually disconnected');
  }
}
