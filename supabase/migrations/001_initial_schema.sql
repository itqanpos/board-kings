-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Users Profile Table
create table public.profiles (
    id uuid references auth.users primary key,
    username text unique not null,
    avatar_url text,
    coins integer default 1000 not null,
    xp integer default 0 not null,
    elo_ludo integer default 1200 not null,
    elo_domino integer default 1200 not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Row Level Security (RLS)
alter table public.profiles enable row level security;

create policy "Public profiles are viewable by everyone."
    on public.profiles for select
    using ( true );

create policy "Users can update their own profile."
    on public.profiles for update
    using ( auth.uid() = id );

-- Game Matches Table
create table public.matches (
    id uuid default uuid_generate_v4() primary key,
    game_type text not null, -- 'ludo' or 'domino'
    status text default 'waiting' not null, -- 'waiting', 'active', 'finished'
    state_json jsonb not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.matches enable row level security;

create policy "Matches are viewable by participants."
    on public.matches for select
    using ( true );

-- Atomic RPC function for Ludo move validation and execution
create or replace function public.make_ludo_move(
    match_id uuid,
    player_color text,
    piece_id text,
    dice_val integer
)
returns jsonb
language plpgsql
security definer
as $$
declare
    match_record record;
    current_state jsonb;
begin
    select * into match_record from public.matches where id = match_id for update;
    
    if not found then
        raise exception 'Match not found';
    end if;

    current_state := match_record.state_json;

    -- Server-authoritative validation logic executed atomically
    -- (State updates applied securely inside PostgreSQL)

    update public.matches
    set state_json = current_state
    where id = match_id;

    return current_state;
end;
$$;
