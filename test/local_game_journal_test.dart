import 'package:board_kings/core/local_game_journal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores and reloads completed local matches without remote services', () async {
    await LocalGameJournal.recordResult(
      game: 'ludo',
      playerCount: 4,
      winner: 'الأحمر',
    );
    await LocalGameJournal.recordResult(
      game: 'domino',
      playerCount: 3,
      winner: 'اللاعب 2',
    );

    final matches = await LocalGameJournal.loadMatches();

    expect(matches, hasLength(2));
    expect(matches.first.game, 'domino');
    expect(matches.first.winner, 'اللاعب 2');
    expect(matches.last.game, 'ludo');
    expect(matches.last.playerCount, 4);
  });

  test('ignores a malformed stored item and keeps valid records readable', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList('board_kings.local_matches.v1', [
      '{not valid json',
      '{"id":"d1","game":"domino","playerCount":2,"winner":"اللاعب 1","completedAt":"2026-01-01T00:00:00.000"}',
    ]);

    final matches = await LocalGameJournal.loadMatches();

    expect(matches, hasLength(1));
    expect(matches.single.id, 'd1');
  });
}
