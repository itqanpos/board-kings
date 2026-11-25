import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../../shared/widgets/game_ui.dart';
import 'data/cosmetic_repository.dart';
import 'models/cosmetic_item.dart';
import 'widgets/cosmetic_artwork.dart';

class CosmeticStoreScreen extends StatefulWidget {
  const CosmeticStoreScreen({super.key});

  @override
  State<CosmeticStoreScreen> createState() => _CosmeticStoreScreenState();
}

class _CosmeticStoreScreenState extends State<CosmeticStoreScreen> {
  late Future<StoreSnapshot> _snapshotFuture;
  String _game = 'ludo';
  String _category = 'all';
  bool _inventoryOnly = false;
  String? _busyItem;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = CosmeticRepository.load();
  }

  void _reload() => setState(() => _snapshotFuture = CosmeticRepository.load());

  Future<void> _openAccount() async {
    await context.push('/account');
    if (mounted) _reload();
  }

  Future<void> _claimDailyReward() async {
    if (!SupabaseConfig.isInitialized) {
      _showMessage('أكمل إعداد Supabase للبدء بمزامنة المكافآت.');
      return;
    }
    if (Supabase.instance.client.auth.currentUser == null) {
      await _openAccount();
      return;
    }

    try {
      final claimed = await CosmeticRepository.claimDailyReward();
      _showMessage(claimed ? 'أُضيفت مكافأة اليوم إلى رصيدك.' : 'استلمت مكافأة اليوم مسبقاً.');
      _reload();
    } catch (_) {
      _showMessage('تعذر استلام المكافأة الآن. حاول مجدداً لاحقاً.');
    }
  }

  Future<void> _activate(CosmeticItem item, StoreSnapshot snapshot) async {
    if (!SupabaseConfig.isInitialized) {
      _showMessage('المعاينة متاحة، لكن الشراء والمزامنة يحتاجان إعداد Supabase.');
      return;
    }
    if (Supabase.instance.client.auth.currentUser == null) {
      await _openAccount();
      return;
    }
    if (_busyItem != null) return;

    setState(() => _busyItem = item.id);
    try {
      if (snapshot.ownedIds.contains(item.id)) {
        await CosmeticRepository.equip(item.id, _game);
        _showMessage('تم تجهيز المظهر في لعبة ${_game == 'ludo' ? 'لودو' : 'الدومينو'}.');
      } else if (item.priceCoins == 0) {
        _showMessage('هذا المظهر الأساسي يُمنح تلقائياً عند إنشاء الحساب.');
      } else {
        await CosmeticRepository.purchase(item.id);
        _showMessage('تم الشراء وإضافة المظهر إلى خزانتي.');
      }
      if (mounted) _reload();
    } on PostgrestException catch (error) {
      final message = error.message.toLowerCase();
      _showMessage(message.contains('insufficient')
          ? 'رصيدك من BOARD COINS لا يكفي لهذا المظهر.'
          : message.contains('already owned')
              ? 'هذا المظهر موجود في خزانتي بالفعل.'
              : 'تعذر تنفيذ العملية. حدّث الصفحة وحاول مجدداً.');
    } catch (_) {
      _showMessage('تعذر تنفيذ العملية الآن. تحقق من الاتصال ثم حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _busyItem = null);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Future<void> _showPreview(CosmeticItem item, StoreSnapshot snapshot) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: panel,
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: mutedText.withOpacity(0.5), borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 17),
              CosmeticArtwork(item: item, height: 190, iconSize: 64),
              const SizedBox(height: 17),
              Row(
                children: [
                  Expanded(child: Text(item.nameAr, style: Theme.of(context).textTheme.titleLarge)),
                  _RarityBadge(rarity: item.rarity),
                ],
              ),
              const SizedBox(height: 7),
              Text(item.descriptionAr, style: const TextStyle(color: mutedText)),
              const SizedBox(height: 8),
              Text('القسم: ${_categoryLabel(item.category)}  •  ${item.gameScope == 'ludo' ? 'لودو' : 'الدومينو'}', style: const TextStyle(color: aqua, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 17),
              GameActionButton(
                label: _actionLabel(item, snapshot),
                icon: snapshot.ownedIds.contains(item.id) ? Icons.check_circle_outline_rounded : item.priceCoins == 0 ? Icons.lock_open_rounded : Icons.shopping_bag_outlined,
                onPressed: _busyItem == item.id || _isEquipped(item, snapshot) ? null : () {
                  Navigator.pop(sheetContext);
                  _activate(item, snapshot);
                },
              ),
              if (!snapshot.ownedIds.contains(item.id) && item.priceCoins > 0) ...[
                const SizedBox(height: 8),
                Text('${item.priceCoins} BOARD COINS', style: const TextStyle(color: gold, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      );

  bool _isEquipped(CosmeticItem item, StoreSnapshot snapshot) =>
      snapshot.equipped['$_game:${item.category}'] == item.id;

  String _actionLabel(CosmeticItem item, StoreSnapshot snapshot) {
    if (_isEquipped(item, snapshot)) return 'مستخدم حالياً';
    if (snapshot.ownedIds.contains(item.id)) return 'استخدم هذا المظهر';
    if (item.priceCoins == 0) return 'مظهر أساسي';
    return 'شراء المظهر';
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'متجر BOARD KINGS',
        trailing: IconButton(
          tooltip: 'الحساب',
          onPressed: _openAccount,
          icon: const Icon(Icons.account_circle_outlined),
        ),
        child: FutureBuilder<StoreSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            final store = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StoreHero(onAccount: _openAccount),
                const SizedBox(height: 15),
                if (store == null && snapshot.hasError)
                  _StoreUnavailable(onRetry: _reload)
                else if (store == null)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                else ...[
                  _WalletPanel(
                    balance: store.balance,
                    accountConnected: SupabaseConfig.isInitialized && Supabase.instance.client.auth.currentUser != null,
                    onClaim: _claimDailyReward,
                    onAccount: _openAccount,
                  ),
                  const SizedBox(height: 17),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(label: 'لودو', selected: _game == 'ludo', onTap: () => setState(() { _game = 'ludo'; _category = 'all'; })),
                      _FilterChip(label: 'الدومينو', selected: _game == 'domino', onTap: () => setState(() { _game = 'domino'; _category = 'all'; })),
                      FilterChip(
                        label: const Text('خزانتي'),
                        selected: _inventoryOnly,
                        onSelected: (value) => setState(() => _inventoryOnly = value),
                        avatar: const Icon(Icons.inventory_2_outlined, size: 17),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    children: [
                      ('all', 'الكل'),
                      ('table', 'الطاولات'),
                      if (_game == 'ludo') ('dice', 'النرد'),
                      if (_game == 'ludo') ('pieces', 'القطع'),
                      if (_game == 'domino') ('tiles', 'الدومينو'),
                    ].map((entry) => ChoiceChip(
                      label: Text(entry.$2),
                      selected: _category == entry.$1,
                      onSelected: (_) => setState(() => _category = entry.$1),
                    )).toList(),
                  ),
                  const SizedBox(height: 14),
                  SectionTitle(_inventoryOnly ? 'مظاهر خزانتي' : 'اكتشف المظاهر', action: '${_visibleItems(store).length} مظهر'),
                  const SizedBox(height: 9),
                  _CosmeticGrid(
                    items: _visibleItems(store),
                    snapshot: store,
                    game: _game,
                    busyItem: _busyItem,
                    onTap: (item) => _showPreview(item, store),
                  ),
                  if (!SupabaseConfig.isInitialized) ...[
                    const SizedBox(height: 14),
                    const _OfflineNotice(),
                  ],
                ],
              ],
            );
          },
        ),
      );

  List<CosmeticItem> _visibleItems(StoreSnapshot snapshot) => snapshot.catalog.where((item) {
        final matchesGame = item.gameScope == _game || item.gameScope == 'shared';
        final matchesCategory = _category == 'all' || item.category == _category;
        final matchesInventory = !_inventoryOnly || snapshot.ownedIds.contains(item.id);
        return matchesGame && matchesCategory && matchesInventory;
      }).toList(growable: false);
}

class _StoreHero extends StatelessWidget {
  const _StoreHero({required this.onAccount});
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF344768), Color(0xFF1D293D), panel]),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: gold.withOpacity(0.27)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: gold.withOpacity(0.16), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.auto_awesome_rounded, color: gold)),
                const SizedBox(width: 12),
                const Expanded(child: Text('طاولتك. أسلوبك.', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 21))),
              ],
            ),
            const SizedBox(height: 10),
            const Text('خصص لودو والدومينو بمظاهر أصلية. كل شيء للّعب فقط؛ لا رهانات ولا صناديق حظ.', style: TextStyle(color: mutedText, height: 1.45)),
            const SizedBox(height: 15),
            OutlinedButton.icon(onPressed: onAccount, icon: const Icon(Icons.person_outline_rounded), label: const Text('الحساب والمزامنة')),
          ],
        ),
      );
}

class _WalletPanel extends StatelessWidget {
  const _WalletPanel({required this.balance, required this.accountConnected, required this.onClaim, required this.onAccount});
  final int? balance;
  final bool accountConnected;
  final VoidCallback onClaim;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(width: 45, height: 45, decoration: BoxDecoration(color: gold.withOpacity(0.14), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.toll_rounded, color: gold, size: 25)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BOARD COINS', style: TextStyle(fontSize: 11, color: mutedText, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(balance?.toString() ?? '—', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: gold)),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: accountConnected ? onClaim : onAccount,
              icon: Icon(accountConnected ? Icons.card_giftcard_rounded : Icons.login_rounded, size: 17),
              label: Text(accountConnected ? 'مكافأة اليوم' : 'ربط الحساب'),
            ),
          ],
        ),
      );
}

class _CosmeticGrid extends StatelessWidget {
  const _CosmeticGrid({required this.items, required this.snapshot, required this.game, required this.busyItem, required this.onTap});
  final List<CosmeticItem> items;
  final StoreSnapshot snapshot;
  final String game;
  final String? busyItem;
  final ValueChanged<CosmeticItem> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SurfaceCard(child: Text('لا توجد مظاهر في هذا القسم بعد.', style: TextStyle(color: mutedText), textAlign: TextAlign.center));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width >= 940 ? (width - 24) / 3 : width >= 620 ? (width - 12) / 2 : width;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            final owned = snapshot.ownedIds.contains(item.id);
            final equipped = snapshot.equipped['$game:${item.category}'] == item.id;
            return SizedBox(
              width: cardWidth,
              child: _CosmeticCard(
                item: item,
                owned: owned,
                equipped: equipped,
                busy: busyItem == item.id,
                onTap: () => onTap(item),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CosmeticCard extends StatelessWidget {
  const _CosmeticCard({required this.item, required this.owned, required this.equipped, required this.busy, required this.onTap});
  final CosmeticItem item;
  final bool owned;
  final bool equipped;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${item.nameAr}، ${_rarityLabel(item.rarity)}، ${owned ? 'مملوك' : '${item.priceCoins} عملة'}',
        child: Material(
          color: panel,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CosmeticArtwork(item: item, height: 126, iconSize: 42),
                      if (item.isFeatured)
                        const Positioned(top: 8, right: 8, child: _Tag(label: 'مميز', color: gold)),
                      if (item.rarity == 'seasonal')
                        const Positioned(top: 8, left: 8, child: _Tag(label: 'موسمي', color: aqua)),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(child: Text(item.nameAr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                      _RarityBadge(rarity: item.rarity),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          owned ? (equipped ? 'مستخدم الآن' : 'في خزانتي') : item.isStarter ? 'أساسي' : '${item.priceCoins} BC',
                          style: TextStyle(color: owned ? aqua : item.isStarter ? mutedText : gold, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                      Icon(owned ? Icons.check_circle_rounded : Icons.visibility_outlined, color: owned ? aqua : mutedText, size: 18),
                      if (busy) ...[const SizedBox(width: 6), const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity});
  final String rarity;

  @override
  Widget build(BuildContext context) {
    final color = switch (rarity) {
      'uncommon' => aqua,
      'rare' => const Color(0xFF81A6FF),
      'epic' => const Color(0xFFD09BFF),
      'legendary' => gold,
      'seasonal' => coral,
      _ => mutedText,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(30)),
      child: Text(_rarityLabel(rarity), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: ink.withOpacity(0.82), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.6))),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) => const SurfaceCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: gold),
            SizedBox(width: 11),
            Expanded(child: Text('هذه معاينة للمظاهر فقط. لا يوجد رصيد أو ملكية افتراضية؛ سجّل إعدادات مشروع Supabase المجاني لتفعيل المزامنة والشراء الآمن.', style: TextStyle(color: mutedText))),
          ],
        ),
      );
}

class _StoreUnavailable extends StatelessWidget {
  const _StoreUnavailable({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: gold, size: 30),
            const SizedBox(height: 10),
            const Text('تعذر تحميل كتالوج المتجر من Supabase.', style: TextStyle(color: mutedText), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
          ],
        ),
      );
}

String _categoryLabel(String category) => switch (category) {
      'table' => 'الطاولات',
      'dice' => 'النرد',
      'pieces' => 'قطع لودو',
      'tiles' => 'قطع الدومينو',
      _ => 'المظاهر',
    };

String _rarityLabel(String rarity) => switch (rarity) {
      'uncommon' => 'غير شائع',
      'rare' => 'نادر',
      'epic' => 'ملحمي',
      'legendary' => 'أسطوري',
      'seasonal' => 'موسمي',
      _ => 'أساسي',
    };
