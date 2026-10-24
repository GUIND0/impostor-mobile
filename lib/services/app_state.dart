import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config.dart';
import '../models/player.dart';
import '../models/room.dart';
import 'api.dart';

class ActionException implements Exception {
  final String code;
  final String message;

  const ActionException(this.code, this.message);

  @override
  String toString() => message;
}

class AppState extends ChangeNotifier {
  static const _tokenKey = 'player_token';

  final Api api = Api();
  Player? player;
  RoomState? room;
  bool ready = false;
  bool connected = false;
  String? startupError;
  List<CategoryInfo> categories = const [];
  Duration _clockOffset = Duration.zero;
  io.Socket? _socket;

  Future<void> init() async {
    startupError = null;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      api.token = token;
      try {
        player = await api.me();
        _connect();
      } on ApiException catch (e) {
        if (e.status == 401) {
          await prefs.remove(_tokenKey);
          api.token = null;
        } else {
          startupError = e.message;
        }
      }
    }
    unawaited(_loadCategories());
    ready = true;
    notifyListeners();
  }

  Future<void> _loadCategories() async {
    try {
      categories = await api.categories();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> createProfile(String name, String? photoPath) async {
    final (created, token) = await api.createPlayer(name);
    api.token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    player = created;
    if (photoPath != null) {
      try {
        player = await api.uploadAvatar(photoPath);
      } catch (_) {}
    }
    _connect();
    notifyListeners();
  }

  Future<void> rename(String name) async {
    player = await api.rename(name);
    notifyListeners();
  }

  Future<void> changeAvatar(String path) async {
    player = await api.uploadAvatar(path);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      player = await api.me();
      notifyListeners();
    } catch (_) {}
  }

  void _connect() {
    _socket?.dispose();
    final socket = io.io(
      AppConfig.apiUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': api.token})
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .disableAutoConnect()
          .build(),
    );
    socket.onConnect((_) {
      connected = true;
      notifyListeners();
    });
    socket.onDisconnect((_) {
      connected = false;
      notifyListeners();
    });
    socket.on('room:state', (data) {
      final json = Map<String, dynamic>.from(data as Map);
      final serverTime = (json['serverTime'] as num?)?.toInt();
      if (serverTime != null) {
        _clockOffset = Duration(milliseconds: serverTime - DateTime.now().millisecondsSinceEpoch);
      }
      room = RoomState.fromJson(json, clockOffset: _clockOffset);
      notifyListeners();
    });
    socket.on('room:left', (_) {
      room = null;
      notifyListeners();
      unawaited(refreshProfile());
    });
    socket.on('room:none', (_) {
      if (room != null) {
        room = null;
        notifyListeners();
      }
    });
    socket.connect();
    _socket = socket;
  }

  Future<dynamic> emit(String event, [Map<String, dynamic>? data]) {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      return Future.error(const ActionException('offline', 'Connexion au serveur perdue'));
    }
    final completer = Completer<dynamic>();
    socket.emitWithAck(
      event,
      data ?? <String, dynamic>{},
      ack: (response) {
        if (completer.isCompleted) return;
        final map = Map<String, dynamic>.from(response as Map);
        if (map['ok'] == true) {
          completer.complete(map['data']);
        } else {
          final error = Map<String, dynamic>.from(map['error'] as Map? ?? {});
          completer.completeError(
            ActionException(
              error['code'] as String? ?? 'error',
              error['message'] as String? ?? 'Action impossible',
            ),
          );
        }
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw const ActionException('timeout', 'Le serveur ne répond pas'),
    );
  }

  Future<void> createRoom() {
    unawaited(_loadCategories());
    return emit('room:create');
  }

  Future<void> joinRoom(String code) => emit('room:join', {'code': code.trim().toUpperCase()});

  Future<void> leaveRoom() async {
    await emit('room:leave');
    room = null;
    notifyListeners();
    unawaited(refreshProfile());
  }

  Future<void> updateSettings(Map<String, dynamic> patch) => emit('room:settings', patch);
  Future<void> kick(String playerId) => emit('room:kick', {'playerId': playerId});
  Future<void> startGame() => emit('game:start');
  Future<void> markSeen() => emit('game:seen');
  Future<void> sendTextClue(String text) => emit('game:clue', {'type': 'text', 'text': text});

  Future<void> sendAudioClue(String filePath, int durationMs) async {
    final url = await api.uploadAudio(filePath);
    await emit('game:clue', {'type': 'audio', 'audioUrl': url, 'durationMs': durationMs});
  }

  Future<void> vote(String targetId) => emit('game:vote', {'targetId': targetId});
  Future<void> guess(String value) => emit('game:guess', {'guess': value});
  Future<void> nextRound() => emit('game:next');
  Future<void> restart() => emit('game:restart');

  bool get isHost => room != null && player != null && room!.hostId == player!.id;

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}
