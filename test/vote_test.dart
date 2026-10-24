import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impostor/models/player.dart';
import 'package:impostor/models/room.dart';
import 'package:impostor/screens/game/results_view.dart';
import 'package:impostor/screens/game/vote_summary.dart';
import 'package:impostor/screens/game/vote_view.dart';
import 'package:impostor/services/app_state.dart';
import 'package:impostor/widgets/avatar.dart';
import 'package:provider/provider.dart';

class FakeAppState extends AppState {
  final sentVotes = <String>[];

  @override
  Future<void> vote(String targetId) async {
    sentVotes.add(targetId);
    room = votingRoom(myVote: targetId, votedIds: [player!.id]);
    notifyListeners();
  }
}

Map<String, dynamic> member(String id, String name) => {
  'id': id,
  'name': name,
  'avatarUrl': null,
  'connected': true,
  'score': 0,
};

RoomState votingRoom({String? myVote, List<String> votedIds = const []}) => RoomState.fromJson({
  'code': 'ABCDE',
  'hostId': 'a',
  'phase': 'voting',
  'deadline': null,
  'serverTime': 0,
  'categoryLabel': 'Aléatoire',
  'settings': {
    'rounds': 3,
    'revealSeconds': 20,
    'imposterMode': 'similar',
    'clueTurns': 1,
    'category': 'random',
    'turnSeconds': 60,
    'voteSeconds': 60,
    'imposterSeesCategory': true,
  },
  'members': [member('a', 'Awa'), member('b', 'Bakary'), member('c', 'Coumba')],
  'round': {
    'number': 1,
    'mode': 'similar',
    'totalRounds': 3,
    'category': 'Animaux',
    'you': {'isImposter': false, 'word': 'Lion', 'seen': true},
    'seenIds': ['a', 'b', 'c'],
    'order': ['a', 'b', 'c'],
    'turn': 2,
    'clueTurns': 1,
    'currentSpeakerId': null,
    'clues': [],
    'votedIds': votedIds,
    'myVote': myVote,
    'accusedId': null,
    'votes': null,
    'result': null,
  },
  'history': [],
  'ranking': null,
});

Widget host(AppState state, Widget child) => ChangeNotifierProvider<AppState>.value(
  value: state,
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('tapping a card sends the vote for that exact player', (tester) async {
    for (final target in [('b', 'Bakary'), ('c', 'Coumba')]) {
      final state = FakeAppState()
        ..player = const Player(id: 'a', name: 'Awa')
        ..room = votingRoom(votedIds: ['b']);
      await tester.pumpWidget(host(state, const VoteView()));
      expect(find.text('Awa'), findsNothing);
      expect(find.text('Bakary'), findsOneWidget);
      expect(find.text('Coumba'), findsOneWidget);
      expect(find.text('Votre vote'), findsNothing);
      await tester.tap(find.text(target.$2));
      await tester.pumpAndSettle();
      expect(state.sentVotes, [target.$1]);
      expect(
        find.text('Votre vote : ${target.$2} · vous pouvez changer tant que tout le monde n’a pas voté'),
        findsOneWidget,
      );
      final card = find.ancestor(of: find.text(target.$2), matching: find.byType(InkWell));
      expect(find.descendant(of: card, matching: find.text('Votre vote')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('a player who has voted is not marked on the voting cards', (tester) async {
    final state = FakeAppState()
      ..player = const Player(id: 'a', name: 'Awa')
      ..room = votingRoom(votedIds: ['b', 'c']);
    await tester.pumpWidget(host(state, const VoteView()));
    for (final name in ['Bakary', 'Coumba']) {
      final card = find.ancestor(of: find.text(name), matching: find.byType(InkWell));
      expect(find.descendant(of: card, matching: find.byIcon(Icons.how_to_vote)), findsNothing);
      expect(find.descendant(of: card, matching: find.text('Votre vote')), findsNothing);
    }
    expect(find.text('Ont déjà voté : 2/3'), findsOneWidget);
  });

  testWidgets('players of a room get distinct avatar colors on every screen', (tester) async {
    final room = votingRoom();
    final indexes = room.members.map((m) => room.colorOf(m.id)).toList();
    expect(indexes.toSet().length, room.members.length);
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Avatar(name: 'Test Bot', colorIndex: indexes[0]),
            Avatar(name: 'Test Bot', colorIndex: indexes[1]),
            Avatar(name: 'Test Bot', colorIndex: indexes[2]),
          ],
        ),
      ),
    );
    final colors = tester
        .widgetList<Container>(find.descendant(of: find.byType(Avatar), matching: find.byType(Container)))
        .map((c) => c.color)
        .whereType<Color>()
        .toSet();
    expect(colors.length, 3);
  });

  group('real server payload', () {
    final fixture =
        jsonDecode(File('test/fixtures/results_payload.json').readAsStringSync()) as Map<String, dynamic>;
    final names = (fixture['names'] as Map<String, dynamic>).cast<String, String>();
    final plan = (fixture['plan'] as Map<String, dynamic>).cast<String, String>();
    final room = RoomState.fromJson(fixture['state'] as Map<String, dynamic>);

    test('parsed votes match what each player sent', () {
      expect(room.round!.votes, plan);
      expect(room.round!.myVote, plan[fixture['viewer']]);
    });

    testWidgets('vote summary shows who voted for whom', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: VoteSummary(room: room)),
        ),
      );
      final byTarget = <String, List<String>>{};
      plan.forEach((voter, target) => byTarget.putIfAbsent(target, () => []).add(voter));
      for (final entry in byTarget.entries) {
        final row = find.ancestor(of: find.text(names[entry.key]!), matching: find.byType(Row)).first;
        final voters = entry.value.map((id) => names[id]!).join(', ');
        expect(find.descendant(of: row, matching: find.text('Voté par : $voters')), findsOneWidget);
        final count = entry.value.length;
        expect(
          find.descendant(of: row, matching: find.text('$count vote${count > 1 ? 's' : ''}')),
          findsOneWidget,
        );
      }
      for (final id in names.keys.where((id) => !byTarget.containsKey(id))) {
        expect(find.text(names[id]!), findsNothing);
      }
    });

    testWidgets('results screen shows the same vote details', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      addTearDown(tester.view.resetPhysicalSize);
      final state = FakeAppState()
        ..player = Player(id: fixture['viewer'] as String, name: names[fixture['viewer']]!)
        ..room = room;
      await tester.pumpWidget(host(state, const ResultsView()));
      await tester.tap(find.text('Détail des votes'));
      await tester.pumpAndSettle();
      plan.forEach((voter, target) {
        expect(find.textContaining(names[voter]!), findsWidgets);
      });
      final imposter = names[room.round!.result!.imposterId]!;
      expect(find.text("$imposter était l'imposteur"), findsOneWidget);
    });
  });
}
