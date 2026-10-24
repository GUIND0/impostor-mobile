import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config.dart';
import '../models/player.dart';

class ApiException implements Exception {
  final int status;
  final String message;

  const ApiException(this.status, this.message);

  @override
  String toString() => message;
}

class Api {
  String? token;
  final http.Client _client = http.Client();

  Uri _uri(String path) => Uri.parse('${AppConfig.apiUrl}$path');

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final message = body is Map && body['message'] is String
        ? body['message'] as String
        : 'Erreur ${res.statusCode}';
    throw ApiException(res.statusCode, message);
  }

  Future<dynamic> _send(Future<http.Response> request) async {
    try {
      return _decode(await request.timeout(const Duration(seconds: 20)));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(0, 'Impossible de joindre le serveur');
    }
  }

  Future<(Player, String)> createPlayer(String name) async {
    final data =
        await _send(_client.post(_uri('/api/players'), headers: _headers, body: jsonEncode({'name': name})))
            as Map<String, dynamic>;
    return (Player.fromJson(data['player'] as Map<String, dynamic>), data['token'] as String);
  }

  Future<Player> me() async {
    final data = await _send(_client.get(_uri('/api/players/me'), headers: _headers));
    return Player.fromJson(data as Map<String, dynamic>);
  }

  Future<Player> rename(String name) async {
    final data = await _send(
      _client.patch(_uri('/api/players/me'), headers: _headers, body: jsonEncode({'name': name})),
    );
    return Player.fromJson(data as Map<String, dynamic>);
  }

  Future<dynamic> _upload(String path, String filePath, MediaType type) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath, contentType: type));
    try {
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      return _decode(await http.Response.fromStream(streamed));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(0, "Échec de l'envoi du fichier");
    }
  }

  Future<Player> uploadAvatar(String filePath) async {
    final lower = filePath.toLowerCase();
    final type = lower.endsWith('.png')
        ? MediaType('image', 'png')
        : lower.endsWith('.webp')
        ? MediaType('image', 'webp')
        : MediaType('image', 'jpeg');
    final data = await _upload('/api/players/me/avatar', filePath, type);
    return Player.fromJson(data as Map<String, dynamic>);
  }

  Future<String> uploadAudio(String filePath) async {
    final data = await _upload('/api/audio', filePath, MediaType('audio', 'mp4'));
    return (data as Map<String, dynamic>)['audioUrl'] as String;
  }

  Future<List<CategoryInfo>> categories() async {
    final data = await _send(_client.get(_uri('/api/categories'), headers: _headers)) as List;
    return data.map((c) => CategoryInfo.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<List<Player>> leaderboard() async {
    final data = await _send(_client.get(_uri('/api/leaderboard'), headers: _headers)) as List;
    return data.map((p) => Player.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<List<GameSummary>> myGames() async {
    final data = await _send(_client.get(_uri('/api/players/me/games'), headers: _headers)) as List;
    return data.map((g) => GameSummary.fromJson(g as Map<String, dynamic>)).toList();
  }
}
