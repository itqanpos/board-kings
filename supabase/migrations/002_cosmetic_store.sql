begin;

create table if not exists public.player_wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance integer not null default 0 check (balance >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.cosmetic_items (
  id text primary key,
  game_scope text not null check (game_scope in ('ludo', 'domino', 'shared')),
  category text not null check (category in ('table', 'dice', 'pieces', 'tiles')),
  name_ar text not null,
  description_ar text not null,
  rarity text not null check (rarity in ('common', 'uncommon', 'rare', 'epic', 'legendary', 'seasonal')),
  price_coins integer not null check (price_coins >= 0),
  preview_style text not null,
  is_active boolean not null default true,
  is_featured boolean not null default false,
  created_at timestamptz not null default now(),
  check (
    (game_scope = 'ludo' and category in ('table', 'dice', 'pieces')) or
    (game_scope = 'domino' and category in ('table', 'tiles')) or
    (game_scope = 'shared' and category = 'table')
  )
);

create table if not exists public.player_inventory (
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id text not null references public.cosmetic_items(id) on delete restrict,
  acquired_at timestamptz not null default now(),
  acquisition_source text not null check (acquisition_source in ('starter', 'purchase', 'reward', 'seasonal')),
  primary key (user_id, item_id)
);

create table if not exists public.player_equipped_items (
  user_id uuid not null references auth.users(id) on delete cascade,
  game_key text not null check (game_key in ('ludo', 'domino')),
  category text not null check (category in ('table', 'dice', 'pieces', 'tiles')),
  item_id text not null references public.cosmetic_items(id) on delete restrict,
  equipped_at timestamptz not null default now(),
  primary key (user_id, game_key, category),
  check (
    (game_key = 'ludo' and category in ('table', 'dice', 'pieces')) or
    (game_key = 'domino' and category in ('table', 'tiles'))
  )
);

create table if not exists public.store_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  transaction_type text not null check (transaction_type in ('purchase', 'daily_reward', 'match_reward', 'achievement_reward')),
  reference_id text not null,
  coins_delta integer not null check (coins_delta <> 0),
  balance_after integer not null check (balance_after >= 0),
  idempotency_key uuid not null,
  created_at timestamptz not null default now(),
  unique (user_id, idempotency_key)
);

create table if not exists public.player_rewards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  reward_code text not null,
  claimed_on date not null,
  coins_awarded integer not null check (coins_awarded > 0),
  claimed_at timestamptz not null default now(),
  unique (user_id, reward_code, claimed_on)
);

create index if not exists cosmetic_items_catalog_idx
  on public.cosmetic_items (game_scope, category, is_active, price_coins);
create index if not exists store_transactions_user_time_idx
  on public.store_transactions (user_id, created_at desc);

insert into public.cosmetic_items
  (id, game_scope, category, name_ar, description_ar, rarity, price_coins, preview_style, is_active, is_featured)
values
  ('ludo_table_classic', 'ludo', 'table', 'الطاولة الكلاسيكية', 'ألوان هادئة وبداية أصيلة لكل جولة.', 'common', 0, 'classic', true, false),
  ('ludo_table_oak', 'ludo', 'table', 'خشب البلوط', 'إطار خشبي دافئ بتفاصيل مصقولة.', 'uncommon', 160, 'oak', true, false),
  ('ludo_table_regal', 'ludo', 'table', 'المجلس الملكي', 'لمسات ذهبية عميقة لأجواء ملكية.', 'rare', 280, 'regal', true, true),
  ('ludo_table_neon', 'ludo', 'table', 'وهج المدينة', 'سطح ليلي بخطوط ضوئية نابضة.', 'epic', 360, 'neon', true, true),
  ('ludo_table_galaxy', 'ludo', 'table', 'مدار النجوم', 'ألوان فضائية هادئة ولمعة سماوية.', 'epic', 450, 'galaxy', true, false),
  ('ludo_table_forest', 'ludo', 'table', 'غابة الصنوبر', 'أخضر طبيعي بدرجات مريحة للعين.', 'uncommon', 200, 'forest', true, false),
  ('ludo_dice_classic', 'ludo', 'dice', 'نرد اللعب', 'مظهر واضح يحافظ على قراءة كل نتيجة.', 'common', 0, 'classic', true, false),
  ('ludo_dice_gold', 'ludo', 'dice', 'نرد ذهبي', 'حواف ذهبية لامعة ونقاط عالية التباين.', 'rare', 150, 'gold', true, false),
  ('ludo_dice_crystal', 'ludo', 'dice', 'نرد كريستالي', 'انعكاس بلوري مع نقاط داكنة واضحة.', 'epic', 260, 'crystal', true, true),
  ('ludo_dice_flame', 'ludo', 'dice', 'نرد الجمر', 'تدرج ناري زخرفي دون أي تغيير للنتيجة.', 'epic', 320, 'flame', true, false),
  ('ludo_dice_neon', 'ludo', 'dice', 'نرد النيون', 'إطار مضيء مع نقاط مقروءة.', 'rare', 240, 'neon', true, false),
  ('ludo_dice_crown', 'ludo', 'dice', 'نرد التاج', 'تفاصيل ملكية بارزة للّاعب المميز.', 'legendary', 420, 'crown', true, true),
  ('ludo_pieces_classic', 'ludo', 'pieces', 'قطع لودو الأصلية', 'شكل القطع الأساسي مع ألوان اللاعبين الواضحة.', 'common', 0, 'classic', true, false),
  ('ludo_pieces_gold', 'ludo', 'pieces', 'قطع مذهبة', 'لمعة ذهبية مع بقاء لون اللاعب أساسياً.', 'rare', 180, 'gold', true, false),
  ('ludo_pieces_crystal', 'ludo', 'pieces', 'قطع كريستال', 'سطح بلوري شفاف المظهر وحدود واضحة.', 'epic', 300, 'crystal', true, true),
  ('ludo_pieces_crown', 'ludo', 'pieces', 'قطع التاج', 'زخرفة ملكية فاخرة للقطع الأربع.', 'legendary', 400, 'crown', true, false),
  ('ludo_pieces_neon', 'ludo', 'pieces', 'قطع مضيئة', 'حواف متوهجة تميز القطع على اللوحة.', 'rare', 260, 'neon', true, false),
  ('domino_table_classic', 'domino', 'table', 'طاولة الدومينو الكلاسيكية', 'سطح اللعب التقليدي لسهرة هادئة.', 'common', 0, 'classic', true, false),
  ('domino_table_oak', 'domino', 'table', 'طاولة السنديان', 'حبيبات خشب دافئة وإطار أنيق.', 'uncommon', 160, 'oak', true, false),
  ('domino_table_marble', 'domino', 'table', 'رخام الليل', 'رخام داكن بلمعة راقية.', 'rare', 260, 'marble', true, true),
  ('domino_table_royal', 'domino', 'table', 'طاولة العرش', 'حواف ذهبية لقاعة اللعب الملكية.', 'epic', 380, 'regal', true, false),
  ('domino_table_desert', 'domino', 'table', 'واحة الرمال', 'درجات رملية مستوحاة من دفء الصحراء.', 'uncommon', 220, 'desert', true, false),
  ('domino_table_winter', 'domino', 'table', 'شتاء الشفق', 'إصدار موسمي بألوان جليدية هادئة.', 'seasonal', 300, 'winter', true, true),
  ('domino_tiles_classic', 'domino', 'tiles', 'قطع الدومينو الأصلية', 'عاجي كلاسيكي وأرقام عالية الوضوح.', 'common', 0, 'classic', true, false),
  ('domino_tiles_wood', 'domino', 'tiles', 'دومينو خشبي', 'نقشة بلوط مع أرقام داكنة بارزة.', 'uncommon', 150, 'oak', true, false),
  ('domino_tiles_ivory', 'domino', 'tiles', 'دومينو العاج', 'عاج دافئ ونقاط واضحة من النظرة الأولى.', 'rare', 210, 'ivory', true, false),
  ('domino_tiles_gold', 'domino', 'tiles', 'دومينو ذهبي', 'حواف ذهبية دون المساس بقيم القطع.', 'epic', 360, 'gold', true, true),
  ('domino_tiles_obsidian', 'domino', 'tiles', 'سبج فاخر', 'أسود عميق مع أرقام فاتحة عالية التباين.', 'epic', 280, 'obsidian', true, false),
  ('domino_tiles_neon', 'domino', 'tiles', 'دومينو المستقبل', 'حواف مضيئة مع أرقام سهلة القراءة.', 'legendary', 400, 'neon', true, true)
on conflict (id) do nothing;

alter table public.profiles enable row level security;
drop policy if exists "Public profiles are viewable by everyone." on public.profiles;
drop policy if exists "Users can update their own profile." on public.profiles;
revoke all on public.profiles from anon, authenticated;
alter table public.profiles alter column coins set default 0;
update public.profiles set coins = 0 where coins <> 0;
grant select, update (username, avatar_url) on public.profiles to authenticated;
create policy profiles_select_own on public.profiles for select to authenticated using (auth.uid() = id);
create policy profiles_update_own on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- The existing Flutter game is local-only; its placeholder match RPC has no authorization checks.
drop policy if exists "Matches are viewable by participants." on public.matches;
revoke all on public.matches from anon, authenticated;
revoke all on function public.make_ludo_move(uuid, text, text, integer) from public, anon, authenticated;

alter table public.player_wallets enable row level security;
alter table public.cosmetic_items enable row level security;
alter table public.player_inventory enable row level security;
alter table public.player_equipped_items enable row level security;
alter table public.store_transactions enable row level security;
alter table public.player_rewards enable row level security;

revoke all on public.player_wallets, public.cosmetic_items, public.player_inventory,
  public.player_equipped_items, public.store_transactions, public.player_rewards
from anon, authenticated;
grant select on public.player_wallets to authenticated;
grant select on public.cosmetic_items to anon, authenticated;
grant select on public.player_inventory to authenticated;
grant select on public.player_equipped_items to authenticated;
grant select on public.store_transactions to authenticated;
grant select on public.player_rewards to authenticated;

create policy player_wallets_select_own on public.player_wallets for select to authenticated using (auth.uid() = user_id);
create policy cosmetic_items_read_active on public.cosmetic_items for select to anon, authenticated using (is_active);
create policy player_inventory_select_own on public.player_inventory for select to authenticated using (auth.uid() = user_id);
create policy player_equipped_select_own on public.player_equipped_items for select to authenticated using (auth.uid() = user_id);
create policy store_transactions_select_own on public.store_transactions for select to authenticated using (auth.uid() = user_id);
create policy player_rewards_select_own on public.player_rewards for select to authenticated using (auth.uid() = user_id);

insert into public.player_wallets (user_id, balance)
select p.id, 0 from public.profiles p
on conflict (user_id) do nothing;

insert into public.player_inventory (user_id, item_id, acquisition_source)
select p.id, starters.item_id, 'starter'
from public.profiles p
cross join (values
  ('ludo_table_classic'), ('ludo_dice_classic'), ('ludo_pieces_classic'),
  ('domino_table_classic'), ('domino_tiles_classic')
) as starters(item_id)
on conflict (user_id, item_id) do nothing;

insert into public.player_equipped_items (user_id, game_key, category, item_id)
select p.id, starters.game_key, starters.category, starters.item_id
from public.profiles p
cross join (values
  ('ludo', 'table', 'ludo_table_classic'),
  ('ludo', 'dice', 'ludo_dice_classic'),
  ('ludo', 'pieces', 'ludo_pieces_classic'),
  ('domino', 'table', 'domino_table_classic'),
  ('domino', 'tiles', 'domino_tiles_classic')
) as starters(game_key, category, item_id)
on conflict (user_id, game_key, category) do nothing;

create or replace function public.handle_new_board_kings_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, username)
  values (new.id, 'player_' || pg_catalog.substr(new.id::text, 1, 16))
  on conflict (id) do nothing;

  insert into public.player_wallets (user_id, balance)
  values (new.id, 0)
  on conflict (user_id) do nothing;

  insert into public.player_inventory (user_id, item_id, acquisition_source)
  select new.id, starters.item_id, 'starter'
  from (values
    ('ludo_table_classic'), ('ludo_dice_classic'), ('ludo_pieces_classic'),
    ('domino_table_classic'), ('domino_tiles_classic')
  ) as starters(item_id)
  where exists (
    select 1 from public.cosmetic_items c where c.id = starters.item_id
  )
  on conflict (user_id, item_id) do nothing;

  insert into public.player_equipped_items (user_id, game_key, category, item_id)
  select new.id, starters.game_key, starters.category, starters.item_id
  from (values
    ('ludo', 'table', 'ludo_table_classic'),
    ('ludo', 'dice', 'ludo_dice_classic'),
    ('ludo', 'pieces', 'ludo_pieces_classic'),
    ('domino', 'table', 'domino_table_classic'),
    ('domino', 'tiles', 'domino_tiles_classic')
  ) as starters(game_key, category, item_id)
  where exists (
    select 1 from public.cosmetic_items c where c.id = starters.item_id
  )
  on conflict (user_id, game_key, category) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_board_kings_user() from public, anon, authenticated;
drop trigger if exists on_auth_user_created_board_kings on auth.users;
create trigger on_auth_user_created_board_kings
after insert on auth.users
for each row execute function public.handle_new_board_kings_user();

create or replace function public.buy_cosmetic(p_item_id text, p_idempotency_key uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_item public.cosmetic_items%rowtype;
  v_balance integer;
  v_existing public.store_transactions%rowtype;
begin
  if v_user_id is null then raise exception 'Authentication required' using errcode = '28000'; end if;
  if p_idempotency_key is null or p_item_id is null then raise exception 'Invalid purchase request' using errcode = '22023'; end if;

  select w.balance into v_balance from public.player_wallets w where w.user_id = v_user_id for update;
  if not found then raise exception 'Wallet not found' using errcode = 'P0002'; end if;

  select t.* into v_existing from public.store_transactions t
  where t.user_id = v_user_id and t.idempotency_key = p_idempotency_key;
  if found then
    if v_existing.transaction_type <> 'purchase' or v_existing.reference_id <> p_item_id then
      raise exception 'Idempotency key already used' using errcode = '22023';
    end if;
    return pg_catalog.jsonb_build_object('success', true, 'replayed', true, 'item_id', p_item_id, 'balance', v_existing.balance_after);
  end if;

  select c.* into v_item from public.cosmetic_items c where c.id = p_item_id and c.is_active for share;
  if not found or v_item.price_coins <= 0 then raise exception 'Item cannot be purchased' using errcode = 'P0002'; end if;
  if exists (select 1 from public.player_inventory i where i.user_id = v_user_id and i.item_id = p_item_id) then
    raise exception 'Item already owned' using errcode = '23505';
  end if;
  if v_balance < v_item.price_coins then raise exception 'Insufficient BOARD COINS' using errcode = 'P0001'; end if;

  v_balance := v_balance - v_item.price_coins;
  update public.player_wallets set balance = v_balance, updated_at = now() where user_id = v_user_id;
  insert into public.player_inventory (user_id, item_id, acquisition_source)
  values (v_user_id, p_item_id, case when v_item.rarity = 'seasonal' then 'seasonal' else 'purchase' end);
  insert into public.store_transactions (user_id, transaction_type, reference_id, coins_delta, balance_after, idempotency_key)
  values (v_user_id, 'purchase', p_item_id, -v_item.price_coins, v_balance, p_idempotency_key);

  return pg_catalog.jsonb_build_object('success', true, 'replayed', false, 'item_id', p_item_id, 'balance', v_balance);
end;
$$;

create or replace function public.equip_cosmetic(p_item_id text, p_game_key text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_item public.cosmetic_items%rowtype;
begin
  if v_user_id is null then raise exception 'Authentication required' using errcode = '28000'; end if;
  if p_game_key is null or p_game_key not in ('ludo', 'domino') then raise exception 'Invalid game' using errcode = '22023'; end if;

  select c.* into v_item from public.cosmetic_items c where c.id = p_item_id;
  if not found then raise exception 'Item not found' using errcode = 'P0002'; end if;
  if v_item.game_scope not in (p_game_key, 'shared') then raise exception 'Item belongs to another game' using errcode = '22023'; end if;
  if (p_game_key = 'ludo' and v_item.category not in ('table', 'dice', 'pieces')) or
     (p_game_key = 'domino' and v_item.category not in ('table', 'tiles')) then
    raise exception 'Item category is not supported in this game' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.player_inventory i where i.user_id = v_user_id and i.item_id = p_item_id
  ) then raise exception 'Item is not owned' using errcode = '42501'; end if;

  insert into public.player_equipped_items (user_id, game_key, category, item_id)
  values (v_user_id, p_game_key, v_item.category, p_item_id)
  on conflict (user_id, game_key, category)
  do update set item_id = excluded.item_id, equipped_at = now();

  return pg_catalog.jsonb_build_object('success', true, 'game_key', p_game_key, 'category', v_item.category, 'item_id', p_item_id);
end;
$$;

create or replace function public.claim_daily_reward(p_idempotency_key uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := (timezone('utc', now()))::date;
  v_balance integer;
  v_existing public.store_transactions%rowtype;
  v_reward_amount constant integer := 25;
begin
  if v_user_id is null then raise exception 'Authentication required' using errcode = '28000'; end if;
  if p_idempotency_key is null then raise exception 'Invalid reward request' using errcode = '22023'; end if;
  if not exists (
    select 1 from auth.users u where u.id = v_user_id and u.email_confirmed_at is not null
  ) then raise exception 'Email confirmation required' using errcode = '42501'; end if;

  select w.balance into v_balance from public.player_wallets w where w.user_id = v_user_id for update;
  if not found then raise exception 'Wallet not found' using errcode = 'P0002'; end if;

  select t.* into v_existing from public.store_transactions t
  where t.user_id = v_user_id and t.idempotency_key = p_idempotency_key;
  if found then
    if v_existing.transaction_type <> 'daily_reward' or v_existing.reference_id <> v_today::text then
      raise exception 'Idempotency key already used' using errcode = '22023';
    end if;
    return pg_catalog.jsonb_build_object('claimed', true, 'replayed', true, 'reward', -v_existing.coins_delta, 'balance', v_existing.balance_after);
  end if;

  if exists (
    select 1 from public.player_rewards r
    where r.user_id = v_user_id and r.reward_code = 'daily_login' and r.claimed_on = v_today
  ) then
    return pg_catalog.jsonb_build_object('claimed', false, 'reward', 0, 'balance', v_balance);
  end if;

  v_balance := v_balance + v_reward_amount;
  insert into public.player_rewards (user_id, reward_code, claimed_on, coins_awarded)
  values (v_user_id, 'daily_login', v_today, v_reward_amount);
  update public.player_wallets set balance = v_balance, updated_at = now() where user_id = v_user_id;
  insert into public.store_transactions (user_id, transaction_type, reference_id, coins_delta, balance_after, idempotency_key)
  values (v_user_id, 'daily_reward', v_today::text, v_reward_amount, v_balance, p_idempotency_key);

  return pg_catalog.jsonb_build_object('claimed', true, 'replayed', false, 'reward', v_reward_amount, 'balance', v_balance);
end;
$$;

revoke all on function public.buy_cosmetic(text, uuid) from public, anon;
revoke all on function public.equip_cosmetic(text, text) from public, anon;
revoke all on function public.claim_daily_reward(uuid) from public, anon;
grant execute on function public.buy_cosmetic(text, uuid) to authenticated;
grant execute on function public.equip_cosmetic(text, text) to authenticated;
grant execute on function public.claim_daily_reward(uuid) to authenticated;

commit;
