import 'package:flutter_test/flutter_test.dart';
import 'package:impostor/models/room.dart';

void main() {
  test('parses a room state for the imposter', () {
    final room = RoomState.fromJson({
      'code': 'ABCDE',
      'hostId': 'a',
      'phase': 'clues',
      'deadline': 2000,
      'serverTime': 1000,
      'settings': {
        'rounds': 3,
        'clueTurns': 2,
        'category': 'random',
        'turnSeconds': 60,
        'voteSeconds': 60,
        'imposterSeesCategory': true,
      },
      'members': [
        {'id': 'a', 'name': 'Awa', 'avatarUrl': null, 'connected': true, 'score': 2},
        {'id': 'b', 'name': 'Moussa', 'avatarUrl': '/uploads/avatars/x.jpg', 'connected': false, 'score': 0},
      ],
      'round': {
        'number': 1,
        'totalRounds': 3,
        'category': 'Animaux',
        'you': {'isImposter': true, 'word': null, 'seen': true},
        'seenIds': ['a', 'b'],
        'order': ['b', 'a'],
        'turn': 1,
        'clueTurns': 2,
        'currentSpeakerId': 'a',
        'clues': [
          {
            'id': 'c1',
            'playerId': 'b',
            'turn': 1,
            'type': 'audio',
            'audioUrl': '/uploads/audio/x.m4a',
            'durationMs': 1200,
            'createdAt': 1,
          },
        ],
        'votedIds': [],
        'myVote': null,
        'accusedId': null,
        'votes': null,
        'result': null,
      },
      'history': [],
      'ranking': null,
    });
    expect(room.phase, Phase.clues);
    expect(room.round!.isImposter, isTrue);
    expect(room.round!.word, isNull);
    expect(room.round!.clues.single.isAudio, isTrue);
    expect(room.member('b')!.connected, isFalse);
    expect(room.deadline!.millisecondsSinceEpoch, 2000);
  });
}
