class CosmeticItem {
  const CosmeticItem({
    required this.id,
    required this.gameScope,
    required this.category,
    required this.nameAr,
    required this.descriptionAr,
    required this.rarity,
    required this.priceCoins,
    required this.previewStyle,
    this.isFeatured = false,
  });

  final String id;
  final String gameScope;
  final String category;
  final String nameAr;
  final String descriptionAr;
  final String rarity;
  final int priceCoins;
  final String previewStyle;
  final bool isFeatured;

  bool get isStarter => priceCoins == 0;

  factory CosmeticItem.fromJson(Map<String, dynamic> json) => CosmeticItem(
        id: json['id'] as String,
        gameScope: json['game_scope'] as String,
        category: json['category'] as String,
        nameAr: json['name_ar'] as String,
        descriptionAr: json['description_ar'] as String,
        rarity: json['rarity'] as String,
        priceCoins: (json['price_coins'] as num).toInt(),
        previewStyle: json['preview_style'] as String,
        isFeatured: json['is_featured'] as bool? ?? false,
      );

  static const catalog = <CosmeticItem>[
    CosmeticItem(id: 'ludo_table_classic', gameScope: 'ludo', category: 'table', nameAr: 'الطاولة الكلاسيكية', descriptionAr: 'ألوان هادئة وبداية أصيلة لكل جولة.', rarity: 'common', priceCoins: 0, previewStyle: 'classic'),
    CosmeticItem(id: 'ludo_table_oak', gameScope: 'ludo', category: 'table', nameAr: 'خشب البلوط', descriptionAr: 'إطار خشبي دافئ بتفاصيل مصقولة.', rarity: 'uncommon', priceCoins: 160, previewStyle: 'oak'),
    CosmeticItem(id: 'ludo_table_regal', gameScope: 'ludo', category: 'table', nameAr: 'المجلس الملكي', descriptionAr: 'لمسات ذهبية عميقة لأجواء ملكية.', rarity: 'rare', priceCoins: 280, previewStyle: 'regal', isFeatured: true),
    CosmeticItem(id: 'ludo_table_neon', gameScope: 'ludo', category: 'table', nameAr: 'وهج المدينة', descriptionAr: 'سطح ليلي بخطوط ضوئية نابضة.', rarity: 'epic', priceCoins: 360, previewStyle: 'neon', isFeatured: true),
    CosmeticItem(id: 'ludo_table_galaxy', gameScope: 'ludo', category: 'table', nameAr: 'مدار النجوم', descriptionAr: 'ألوان فضائية هادئة ولمعة سماوية.', rarity: 'epic', priceCoins: 450, previewStyle: 'galaxy'),
    CosmeticItem(id: 'ludo_table_forest', gameScope: 'ludo', category: 'table', nameAr: 'غابة الصنوبر', descriptionAr: 'أخضر طبيعي بدرجات مريحة للعين.', rarity: 'uncommon', priceCoins: 200, previewStyle: 'forest'),
    CosmeticItem(id: 'ludo_dice_classic', gameScope: 'ludo', category: 'dice', nameAr: 'نرد اللعب', descriptionAr: 'مظهر واضح يحافظ على قراءة كل نتيجة.', rarity: 'common', priceCoins: 0, previewStyle: 'classic'),
    CosmeticItem(id: 'ludo_dice_gold', gameScope: 'ludo', category: 'dice', nameAr: 'نرد ذهبي', descriptionAr: 'حواف ذهبية لامعة ونقاط عالية التباين.', rarity: 'rare', priceCoins: 150, previewStyle: 'gold'),
    CosmeticItem(id: 'ludo_dice_crystal', gameScope: 'ludo', category: 'dice', nameAr: 'نرد كريستالي', descriptionAr: 'انعكاس بلوري مع نقاط داكنة واضحة.', rarity: 'epic', priceCoins: 260, previewStyle: 'crystal', isFeatured: true),
    CosmeticItem(id: 'ludo_dice_flame', gameScope: 'ludo', category: 'dice', nameAr: 'نرد الجمر', descriptionAr: 'تدرج ناري زخرفي دون أي تغيير للنتيجة.', rarity: 'epic', priceCoins: 320, previewStyle: 'flame'),
    CosmeticItem(id: 'ludo_dice_neon', gameScope: 'ludo', category: 'dice', nameAr: 'نرد النيون', descriptionAr: 'إطار مضيء مع نقاط مقروءة.', rarity: 'rare', priceCoins: 240, previewStyle: 'neon'),
    CosmeticItem(id: 'ludo_dice_crown', gameScope: 'ludo', category: 'dice', nameAr: 'نرد التاج', descriptionAr: 'تفاصيل ملكية بارزة للّاعب المميز.', rarity: 'legendary', priceCoins: 420, previewStyle: 'crown', isFeatured: true),
    CosmeticItem(id: 'ludo_pieces_classic', gameScope: 'ludo', category: 'pieces', nameAr: 'قطع لودو الأصلية', descriptionAr: 'شكل القطع الأساسي مع ألوان اللاعبين الواضحة.', rarity: 'common', priceCoins: 0, previewStyle: 'classic'),
    CosmeticItem(id: 'ludo_pieces_gold', gameScope: 'ludo', category: 'pieces', nameAr: 'قطع مذهبة', descriptionAr: 'لمعة ذهبية مع بقاء لون اللاعب أساسياً.', rarity: 'rare', priceCoins: 180, previewStyle: 'gold'),
    CosmeticItem(id: 'ludo_pieces_crystal', gameScope: 'ludo', category: 'pieces', nameAr: 'قطع كريستال', descriptionAr: 'سطح بلوري شفاف المظهر وحدود واضحة.', rarity: 'epic', priceCoins: 300, previewStyle: 'crystal', isFeatured: true),
    CosmeticItem(id: 'ludo_pieces_crown', gameScope: 'ludo', category: 'pieces', nameAr: 'قطع التاج', descriptionAr: 'زخرفة ملكية فاخرة للقطع الأربع.', rarity: 'legendary', priceCoins: 400, previewStyle: 'crown'),
    CosmeticItem(id: 'ludo_pieces_neon', gameScope: 'ludo', category: 'pieces', nameAr: 'قطع مضيئة', descriptionAr: 'حواف متوهجة تميز القطع على اللوحة.', rarity: 'rare', priceCoins: 260, previewStyle: 'neon'),
    CosmeticItem(id: 'domino_table_classic', gameScope: 'domino', category: 'table', nameAr: 'طاولة الدومينو الكلاسيكية', descriptionAr: 'سطح اللعب التقليدي لسهرة هادئة.', rarity: 'common', priceCoins: 0, previewStyle: 'classic'),
    CosmeticItem(id: 'domino_table_oak', gameScope: 'domino', category: 'table', nameAr: 'طاولة السنديان', descriptionAr: 'حبيبات خشب دافئة وإطار أنيق.', rarity: 'uncommon', priceCoins: 160, previewStyle: 'oak'),
    CosmeticItem(id: 'domino_table_marble', gameScope: 'domino', category: 'table', nameAr: 'رخام الليل', descriptionAr: 'رخام داكن بلمعة راقية.', rarity: 'rare', priceCoins: 260, previewStyle: 'marble', isFeatured: true),
    CosmeticItem(id: 'domino_table_royal', gameScope: 'domino', category: 'table', nameAr: 'طاولة العرش', descriptionAr: 'حواف ذهبية لقاعة اللعب الملكية.', rarity: 'epic', priceCoins: 380, previewStyle: 'regal'),
    CosmeticItem(id: 'domino_table_desert', gameScope: 'domino', category: 'table', nameAr: 'واحة الرمال', descriptionAr: 'درجات رملية مستوحاة من دفء الصحراء.', rarity: 'uncommon', priceCoins: 220, previewStyle: 'desert'),
    CosmeticItem(id: 'domino_table_winter', gameScope: 'domino', category: 'table', nameAr: 'شتاء الشفق', descriptionAr: 'إصدار موسمي بألوان جليدية هادئة.', rarity: 'seasonal', priceCoins: 300, previewStyle: 'winter', isFeatured: true),
    CosmeticItem(id: 'domino_tiles_classic', gameScope: 'domino', category: 'tiles', nameAr: 'قطع الدومينو الأصلية', descriptionAr: 'عاجي كلاسيكي وأرقام عالية الوضوح.', rarity: 'common', priceCoins: 0, previewStyle: 'classic'),
    CosmeticItem(id: 'domino_tiles_wood', gameScope: 'domino', category: 'tiles', nameAr: 'دومينو خشبي', descriptionAr: 'نقشة بلوط مع أرقام داكنة بارزة.', rarity: 'uncommon', priceCoins: 150, previewStyle: 'oak'),
    CosmeticItem(id: 'domino_tiles_ivory', gameScope: 'domino', category: 'tiles', nameAr: 'دومينو العاج', descriptionAr: 'عاج دافئ ونقاط واضحة من النظرة الأولى.', rarity: 'rare', priceCoins: 210, previewStyle: 'ivory'),
    CosmeticItem(id: 'domino_tiles_gold', gameScope: 'domino', category: 'tiles', nameAr: 'دومينو ذهبي', descriptionAr: 'حواف ذهبية دون المساس بقيم القطع.', rarity: 'epic', priceCoins: 360, previewStyle: 'gold', isFeatured: true),
    CosmeticItem(id: 'domino_tiles_obsidian', gameScope: 'domino', category: 'tiles', nameAr: 'سبج فاخر', descriptionAr: 'أسود عميق مع أرقام فاتحة عالية التباين.', rarity: 'epic', priceCoins: 280, previewStyle: 'obsidian'),
    CosmeticItem(id: 'domino_tiles_neon', gameScope: 'domino', category: 'tiles', nameAr: 'دومينو المستقبل', descriptionAr: 'حواف مضيئة مع أرقام سهلة القراءة.', rarity: 'legendary', priceCoins: 400, previewStyle: 'neon', isFeatured: true),
  ];
}
