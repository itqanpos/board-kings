begin;

alter table public.matches
  add column created_by uuid references auth.users(id) on delete restrict;

do $$
begin
  if exists (select 1 from public.matches where created_by is null) then
    raise exception 'Cannot secure legacy matches without a verified owner; resolve them before applying this migration';
  end if;
end;
$$;

alter table public.matches
  alter column created_by set not null,
  add constraint matches_game_type_check check (game_type in ('ludo', 'domino')),
  add constraint matches_status_check check (status in ('waiting', 'active', 'finished'));

create table public.match_players (
  match_id uuid not null references public.matches(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  seat smallint not null check (seat between 0 and 3),
  joined_at timestamptz not null default pg_catalog.now(),
  primary key (match_id, user_id),
  unique (match_id, seat)
);

create index match_players_user_match_idx
  on public.match_players (user_id, match_id);

comment on column public.matches.state_json is
  'Shared, non-secret match state only. Never store private player data here; keep it in a separately protected per-player store.';

alter table public.matches enable row level security;
alter table public.match_players enable row level security;

revoke all privileges on public.matches, public.match_players from public, anon, authenticated;
grant select on public.matches, public.match_players to authenticated;

create function public.is_match_participant(p_match_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.match_players as mp
    where mp.match_id = p_match_id
      and mp.user_id = auth.uid()
  );
$$;

revoke all privileges on function public.is_match_participant(uuid) from public, anon;
grant execute on function public.is_match_participant(uuid) to authenticated;

create policy matches_select_participants
  on public.matches
  for select
  to authenticated
  using (public.is_match_participant(id));

create policy match_players_select_participants
  on public.match_players
  for select
  to authenticated
  using (user_id = auth.uid() or public.is_match_participant(match_id));

create function public.create_match(p_game_type text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_match_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if p_game_type is null or p_game_type not in ('ludo', 'domino') then
    raise exception 'Unsupported game type' using errcode = '22023';
  end if;

  insert into public.matches (game_type, status, state_json, created_by)
  values (
    p_game_type,
    'waiting',
    pg_catalog.jsonb_build_object('version', 1, 'phase', 'waiting'),
    v_user_id
  )
  returning id into v_match_id;

  insert into public.match_players (match_id, user_id, seat)
  values (v_match_id, v_user_id, 0);

  return v_match_id;
end;
$$;

create function public.join_match(p_match_id uuid)
returns smallint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_status text;
  v_seat smallint;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if p_match_id is null then
    raise exception 'Match id is required' using errcode = '22023';
  end if;

  select m.status into v_status
  from public.matches as m
  where m.id = p_match_id
  for update;
  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;

  select mp.seat into v_seat
  from public.match_players as mp
  where mp.match_id = p_match_id and mp.user_id = v_user_id;
  if found then
    return v_seat;
  end if;
  if v_status <> 'waiting' then
    raise exception 'Match is not accepting players' using errcode = '55000';
  end if;

  select slots.seat::smallint into v_seat
  from pg_catalog.generate_series(0, 3) as slots(seat)
  where not exists (
    select 1 from public.match_players as mp
    where mp.match_id = p_match_id and mp.seat = slots.seat
  )
  order by slots.seat
  limit 1;
  if v_seat is null then
    raise exception 'Match is full' using errcode = '54000';
  end if;

  insert into public.match_players (match_id, user_id, seat)
  values (p_match_id, v_user_id, v_seat);

  return v_seat;
end;
$$;

create function public.leave_match(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_creator_id uuid;
  v_status text;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if p_match_id is null then
    raise exception 'Match id is required' using errcode = '22023';
  end if;

  select m.created_by, m.status into v_creator_id, v_status
  from public.matches as m
  where m.id = p_match_id
  for update;
  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;
  if not exists (
    select 1 from public.match_players as mp
    where mp.match_id = p_match_id and mp.user_id = v_user_id
  ) then
    raise exception 'Not a match participant' using errcode = '42501';
  end if;
  if v_status <> 'waiting' then
    raise exception 'Players cannot leave through this lobby operation after a match starts' using errcode = '55000';
  end if;

  if v_creator_id = v_user_id then
    delete from public.matches where id = p_match_id;
  else
    delete from public.match_players
    where match_id = p_match_id and user_id = v_user_id;
  end if;
end;
$$;

revoke all privileges on function public.create_match(text) from public, anon;
revoke all privileges on function public.join_match(uuid) from public, anon;
revoke all privileges on function public.leave_match(uuid) from public, anon;
grant execute on function public.create_match(text) to authenticated;
grant execute on function public.join_match(uuid) to authenticated;
grant execute on function public.leave_match(uuid) to authenticated;

commit;
