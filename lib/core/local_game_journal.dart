import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalMatchRecord {
  const LocalMatchRecord({
    required this.id,
    required this.game,
    required this.playerCount,
    required this.winner,
    required this.completedAt,
  });

  final String id;
  final String game;
  final int playerCount;
  final String winner;
  final DateTime completedAt;

  String get gameLabel => game == 'ludo' ? 'لودو' : 'الدومينو';

  factory LocalMatchRecord.fromJson(Map<String, dynamic> json) => LocalMatchRecord(
        id: json['id'] as String,
        game: json['game'] as String,
        playerCount: (json['playerCount'] as num).toInt(),
        winner: json['winner'] as String,
        completedAt: DateTime.parse(json['completedAt'] as String),
      );

  Map<String, Object> toJson() => {
        'id': id,
        'game': game,
        'playerCount': playerCount,
        'winner': winner,
        'completedAt': completedAt.toIso8601String(),
      };
}

class LocalGameJournal {
  LocalGameJournal._();

  static const _matchesKey = 'board_kings.local_matches.v1';
  static const _maximumRecords = 100;
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static Future<List<LocalMatchRecord>> loadMatches() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedRecords = preferences.getStringList(_matchesKey) ?? const [];
    final records = <LocalMatchRecord>[];
    for (final encoded in encodedRecords) {
      try {
        final json = jsonDecode(encoded) as Map<String, dynamic>;
        records.add(LocalMatchRecord.fromJson(json));
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    records.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return records;
  }

  static Future<void> recordResult({
    required String game,
    required int playerCount,
    required String winner,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final completedAt = DateTime.now();
    final record = LocalMatchRecord(
      id: '${game}_${completedAt.microsecondsSinceEpoch}',
      game: game,
      playerCount: playerCount,
      winner: winner,
      completedAt: completedAt,
    );
    final existing = preferences.getStringList(_matchesKey) ?? const [];
    await preferences.setStringList(_matchesKey, [
      jsonEncode(record.toJson()),
      ...existing.take(_maximumRecords - 1),
    ]);
    revision.value++;
  }
}
