class Player {
  final String id;
  final String name;
  final String? avatarUrl;
  final int totalPoints;
  final int gamesPlayed;
  final int wins;

  const Player({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.totalPoints = 0,
    this.gamesPlayed = 0,
    this.wins = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as String,
    name: json['name'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
    gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
    wins: (json['wins'] as num?)?.toInt() ?? 0,
  );
}

class GameSummary {
  final String id;
  final String code;
  final int rounds;
  final DateTime finishedAt;
  final int score;
  final int rank;
  final int players;

  const GameSummary({
    required this.id,
    required this.code,
    required this.rounds,
    required this.finishedAt,
    required this.score,
    required this.rank,
    required this.players,
  });

  factory GameSummary.fromJson(Map<String, dynamic> json) => GameSummary(
    id: json['id'] as String,
    code: json['code'] as String,
    rounds: (json['rounds'] as num).toInt(),
    finishedAt: DateTime.parse(json['finishedAt'] as String).toLocal(),
    score: (json['score'] as num).toInt(),
    rank: (json['rank'] as num).toInt(),
    players: (json['players'] as num).toInt(),
  );
}

class CategoryInfo {
  final String id;
  final String label;

  const CategoryInfo(this.id, this.label);

  factory CategoryInfo.fromJson(Map<String, dynamic> json) =>
      CategoryInfo(json['id'] as String, json['label'] as String);
}
