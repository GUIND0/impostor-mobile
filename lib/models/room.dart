enum Phase { lobby, reveal, clues, voting, guess, results, finished }

Phase _phase(String value) => Phase.values.firstWhere((p) => p.name == value, orElse: () => Phase.lobby);

int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

class RoomSettings {
  final int rounds;
  final int clueTurns;
  final String category;
  final int turnSeconds;
  final int voteSeconds;
  final bool imposterSeesCategory;

  const RoomSettings({
    required this.rounds,
    required this.clueTurns,
    required this.category,
    required this.turnSeconds,
    required this.voteSeconds,
    required this.imposterSeesCategory,
  });

  factory RoomSettings.fromJson(Map<String, dynamic> json) => RoomSettings(
    rounds: _int(json['rounds']),
    clueTurns: _int(json['clueTurns']),
    category: json['category'] as String,
    turnSeconds: _int(json['turnSeconds']),
    voteSeconds: _int(json['voteSeconds']),
    imposterSeesCategory: json['imposterSeesCategory'] as bool? ?? true,
  );
}

class RoomMember {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool connected;
  final int score;

  const RoomMember({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.connected,
    required this.score,
  });

  factory RoomMember.fromJson(Map<String, dynamic> json) => RoomMember(
    id: json['id'] as String,
    name: json['name'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    connected: json['connected'] as bool? ?? false,
    score: _int(json['score']),
  );
}

class Clue {
  final String id;
  final String playerId;
  final int turn;
  final String type;
  final String? text;
  final String? audioUrl;
  final int durationMs;

  const Clue({
    required this.id,
    required this.playerId,
    required this.turn,
    required this.type,
    this.text,
    this.audioUrl,
    this.durationMs = 0,
  });

  bool get isAudio => type == 'audio';
  bool get isSkip => type == 'skip';

  factory Clue.fromJson(Map<String, dynamic> json) => Clue(
    id: json['id'] as String,
    playerId: json['playerId'] as String,
    turn: _int(json['turn']),
    type: json['type'] as String,
    text: json['text'] as String?,
    audioUrl: json['audioUrl'] as String?,
    durationMs: _int(json['durationMs']),
  );
}

class RoundResult {
  final String word;
  final String imposterId;
  final bool caught;
  final String? guess;
  final bool guessCorrect;
  final Map<String, int> points;

  const RoundResult({
    required this.word,
    required this.imposterId,
    required this.caught,
    this.guess,
    required this.guessCorrect,
    required this.points,
  });

  factory RoundResult.fromJson(Map<String, dynamic> json) => RoundResult(
    word: json['word'] as String,
    imposterId: json['imposterId'] as String,
    caught: json['caught'] as bool? ?? false,
    guess: json['guess'] as String?,
    guessCorrect: json['guessCorrect'] as bool? ?? false,
    points: (json['points'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, _int(v))),
  );
}

class RoundState {
  final int number;
  final int totalRounds;
  final String? category;
  final bool isImposter;
  final String? word;
  final bool seen;
  final List<String> seenIds;
  final List<String> order;
  final int turn;
  final int clueTurns;
  final String? currentSpeakerId;
  final List<Clue> clues;
  final List<String> votedIds;
  final String? myVote;
  final String? accusedId;
  final Map<String, String>? votes;
  final RoundResult? result;

  const RoundState({
    required this.number,
    required this.totalRounds,
    this.category,
    required this.isImposter,
    this.word,
    required this.seen,
    required this.seenIds,
    required this.order,
    required this.turn,
    required this.clueTurns,
    this.currentSpeakerId,
    required this.clues,
    required this.votedIds,
    this.myVote,
    this.accusedId,
    this.votes,
    this.result,
  });

  factory RoundState.fromJson(Map<String, dynamic> json) {
    final you = json['you'] as Map<String, dynamic>;
    return RoundState(
      number: _int(json['number']),
      totalRounds: _int(json['totalRounds']),
      category: json['category'] as String?,
      isImposter: you['isImposter'] as bool? ?? false,
      word: you['word'] as String?,
      seen: you['seen'] as bool? ?? false,
      seenIds: List<String>.from(json['seenIds'] as List? ?? []),
      order: List<String>.from(json['order'] as List? ?? []),
      turn: _int(json['turn']),
      clueTurns: _int(json['clueTurns']),
      currentSpeakerId: json['currentSpeakerId'] as String?,
      clues: (json['clues'] as List? ?? []).map((c) => Clue.fromJson(c as Map<String, dynamic>)).toList(),
      votedIds: List<String>.from(json['votedIds'] as List? ?? []),
      myVote: json['myVote'] as String?,
      accusedId: json['accusedId'] as String?,
      votes: (json['votes'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)),
      result: json['result'] == null ? null : RoundResult.fromJson(json['result'] as Map<String, dynamic>),
    );
  }
}

class RankingEntry {
  final String playerId;
  final int score;
  final int rank;

  const RankingEntry(this.playerId, this.score, this.rank);

  factory RankingEntry.fromJson(Map<String, dynamic> json) =>
      RankingEntry(json['playerId'] as String, _int(json['score']), _int(json['rank']));
}

class HistoryEntry {
  final int number;
  final String word;
  final String imposterId;
  final bool caught;

  const HistoryEntry(this.number, this.word, this.imposterId, this.caught);

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    _int(json['number']),
    json['word'] as String,
    json['imposterId'] as String,
    json['caught'] as bool? ?? false,
  );
}

class RoomState {
  final String code;
  final String hostId;
  final Phase phase;
  final RoomSettings settings;
  final DateTime? deadline;
  final List<RoomMember> members;
  final RoundState? round;
  final List<HistoryEntry> history;
  final List<RankingEntry>? ranking;

  const RoomState({
    required this.code,
    required this.hostId,
    required this.phase,
    required this.settings,
    this.deadline,
    required this.members,
    this.round,
    required this.history,
    this.ranking,
  });

  factory RoomState.fromJson(Map<String, dynamic> json, {Duration clockOffset = Duration.zero}) {
    final deadline = json['deadline'];
    return RoomState(
      code: json['code'] as String,
      hostId: json['hostId'] as String,
      phase: _phase(json['phase'] as String),
      settings: RoomSettings.fromJson(json['settings'] as Map<String, dynamic>),
      deadline: deadline == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(_int(deadline)).subtract(clockOffset),
      members: (json['members'] as List).map((m) => RoomMember.fromJson(m as Map<String, dynamic>)).toList(),
      round: json['round'] == null ? null : RoundState.fromJson(json['round'] as Map<String, dynamic>),
      history: (json['history'] as List? ?? [])
          .map((h) => HistoryEntry.fromJson(h as Map<String, dynamic>))
          .toList(),
      ranking: (json['ranking'] as List?)
          ?.map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  RoomMember? member(String? id) {
    if (id == null) return null;
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }
}
