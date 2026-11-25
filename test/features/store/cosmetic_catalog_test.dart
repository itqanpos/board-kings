import 'package:flutter_test/flutter_test.dart';
import 'package:board_kings/features/store/models/cosmetic_item.dart';

void main() {
  group('BOARD KINGS cosmetic catalog', () {
    test('contains unique seeded cosmetic identifiers', () {
      final ids = CosmeticItem.catalog.map((item) => item.id).toSet();
      expect(CosmeticItem.catalog, hasLength(29));
      expect(ids, hasLength(CosmeticItem.catalog.length));
    });

    test('keeps each cosmetic category within its game', () {
      for (final item in CosmeticItem.catalog) {
        if (item.gameScope == 'ludo') {
          expect(['table', 'dice', 'pieces'], contains(item.category));
        }
        if (item.gameScope == 'domino') {
          expect(['table', 'tiles'], contains(item.category));
        }
      }
    });

    test('all prices are non-negative and classic starters are free', () {
      expect(CosmeticItem.catalog.every((item) => item.priceCoins >= 0), isTrue);
      for (final id in [
        'ludo_table_classic',
        'ludo_dice_classic',
        'ludo_pieces_classic',
        'domino_table_classic',
        'domino_tiles_classic',
      ]) {
        final item = CosmeticItem.catalog.singleWhere((entry) => entry.id == id);
        expect(item.isStarter, isTrue, reason: '$id is granted at account creation');
      }
    });
  });
}
