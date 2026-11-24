import 'package:board_kings/app/board_kings_app.dart';
import 'package:board_kings/features/domino/domino_game_screen.dart';
import 'package:board_kings/features/domino/engine/domino_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home screen renders player, games, shortcuts, and recent games', (tester) async {
    await tester.pumpWidget(const BoardKingsApp(initialLocation: '/home'));
    await tester.pumpAndSettle();

    expect(find.text('BOARD KINGS'), findsOneWidget);
    expect(find.text('لاعب محلي'), findsOneWidget);
    expect(find.text('اختر لعبتك'), findsOneWidget);
    expect(find.text('آخر المباريات'), findsOneWidget);
    expect(find.text('الأصدقاء'), findsWidgets);
    expect(find.text('الإعدادات'), findsWidgets);
  });

  testWidgets('game selection opens the Ludo lobby and local game', (tester) async {
    await tester.pumpWidget(const BoardKingsApp(initialLocation: '/home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('كل الألعاب'));
    await tester.pumpAndSettle();
    expect(find.text('ماذا ستلعب اليوم؟'), findsOneWidget);

    await tester.tap(find.text('اختيار اللعبة').first);
    await tester.pumpAndSettle();
    expect(find.text('ردهة لودو'), findsOneWidget);
    expect(find.text('لاعبان'), findsOneWidget);

    await tester.tap(find.text('العب محلياً'));
    await tester.pumpAndSettle();
    expect(find.text('ارمِ النرد'), findsOneWidget);
    expect(find.text('الأحمر'), findsWidgets);
  });

  testWidgets('Domino lobby starts a local game and renders player hands', (tester) async {
    await tester.pumpWidget(const BoardKingsApp(initialLocation: '/domino-lobby'));
    await tester.pumpAndSettle();

    expect(find.text('عدد اللاعبين'), findsOneWidget);
    await tester.tap(find.text('3 لاعبين'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ابدأ مباراة محلية'));
    await tester.pumpAndSettle();

    expect(find.text('الدومينو'), findsOneWidget);
    expect(find.textContaining('يد اللاعب'), findsOneWidget);
    expect(find.textContaining('لاعب 1'), findsWidgets);
    expect(find.textContaining('لاعب 2'), findsWidgets);
    expect(find.textContaining('لاعب 3'), findsWidgets);
  });

  testWidgets('Ludo roll is routed through the playable game screen', (tester) async {
    await tester.pumpWidget(const BoardKingsApp(initialLocation: '/ludo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ارمِ النرد'));
    await tester.pumpAndSettle();

    final skippedTurn = find.textContaining('لا توجد حركة').evaluate().isNotEmpty;
    final selectedMove = find.textContaining('اختر قطعة').evaluate().isNotEmpty;
    expect(skippedTurn || selectedMove, isTrue);
    expect(find.text('لودو'), findsOneWidget);
  });

  testWidgets('Domino tile selection responds to a tap', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DominoTileFace(
            tile: const DominoTile(id: 10, left: 2, right: 5),
            onTap: () => selected = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DominoTileFace));
    expect(selected, isTrue);
  });

  testWidgets('application uses Arabic right-to-left directionality', (tester) async {
    await tester.pumpWidget(const BoardKingsApp(initialLocation: '/home'));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('اختر لعبتك'));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('unknown navigation paths show a recoverable error screen', (tester) async {
    await tester.pumpWidget(const BoardKingsApp(initialLocation: '/not-a-route'));
    await tester.pumpAndSettle();

    expect(find.text('المسار غير متاح'), findsOneWidget);
    expect(find.text('العودة للرئيسية'), findsOneWidget);

    await tester.tap(find.text('العودة للرئيسية'));
    await tester.pumpAndSettle();
    expect(find.text('اختر لعبتك'), findsOneWidget);
  });
}
