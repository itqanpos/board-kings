import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase_config.dart';
import '../models/cosmetic_item.dart';

class StoreSnapshot {
  const StoreSnapshot({required this.catalog, required this.ownedIds, required this.equipped, this.balance});

  final List<CosmeticItem> catalog;
  final Set<String> ownedIds;
  final Map<String, String> equipped;
  final int? balance;
}

class CosmeticRepository {
  CosmeticRepository._();

  static SupabaseClient? get _client => SupabaseConfig.isInitialized ? Supabase.instance.client : null;
  static final _uuid = Uuid();

  static Future<StoreSnapshot> load() async {
    final client = _client;
    if (client == null) {
      return const StoreSnapshot(catalog: CosmeticItem.catalog, ownedIds: {}, equipped: {});
    }

    final rows = await client.from('cosmetic_items').select().eq('is_active', true).order('price_coins');
    final catalog = (rows as List<dynamic>)
        .map((row) => CosmeticItem.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
    final user = client.auth.currentUser;
    if (user == null) return StoreSnapshot(catalog: catalog, ownedIds: const {}, equipped: const {});

    final responses = await Future.wait([
      client.from('player_wallets').select('balance').eq('user_id', user.id).maybeSingle(),
      client.from('player_inventory').select('item_id').eq('user_id', user.id),
      client.from('player_equipped_items').select('game_key,category,item_id').eq('user_id', user.id),
    ]);
    final wallet = responses[0] as Map<String, dynamic>?;
    final inventory = responses[1] as List<dynamic>;
    final equipment = responses[2] as List<dynamic>;

    return StoreSnapshot(
      catalog: catalog,
      ownedIds: inventory.map((row) => (row as Map<String, dynamic>)['item_id'] as String).toSet(),
      equipped: {
        for (final row in equipment.cast<Map<String, dynamic>>())
          '${row['game_key']}:${row['category']}': row['item_id'] as String,
      },
      balance: (wallet?['balance'] as num?)?.toInt(),
    );
  }

  static Future<void> purchase(String itemId) async {
    final client = _requireSignedIn();
    await client.rpc('buy_cosmetic', params: {
      'p_item_id': itemId,
      'p_idempotency_key': _uuid.v4(),
    });
  }

  static Future<void> equip(String itemId, String gameKey) async {
    final client = _requireSignedIn();
    await client.rpc('equip_cosmetic', params: {
      'p_item_id': itemId,
      'p_game_key': gameKey,
    });
  }

  static Future<Map<String, String>> loadEquipment(String gameKey) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return const {};

    final rows = await client
        .from('player_equipped_items')
        .select('category,item_id')
        .eq('user_id', user.id)
        .eq('game_key', gameKey);
    return {
      for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>())
        row['category'] as String: row['item_id'] as String,
    };
  }

  static Future<bool> claimDailyReward() async {
    final client = _requireSignedIn();
    final result = await client.rpc('claim_daily_reward', params: {'p_idempotency_key': _uuid.v4()});
    return (result as Map<String, dynamic>)['claimed'] as bool? ?? false;
  }

  static SupabaseClient _requireSignedIn() {
    final client = _client;
    if (client == null) throw const StoreException('أكمل إعداد اتصال Supabase أولاً.');
    if (client.auth.currentUser == null) throw const StoreException('سجّل الدخول أولاً لمتابعة هذه العملية.');
    return client;
  }
}

class StoreException implements Exception {
  const StoreException(this.message);
  final String message;
  @override
  String toString() => message;
}
