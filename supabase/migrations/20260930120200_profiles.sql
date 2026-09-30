create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  -- Nullable until the user picks one during onboarding.
  username text check (username ~ '^[A-Za-z0-9_]{3,30}$'),
  display_name text check (char_length(display_name) <= 80),
  avatar_url text,
  home_municipio_id bigint references public.municipios (id) on delete set null,
  current_municipio_id bigint references public.municipios (id) on delete set null,
  diaspora_city text check (char_length(diaspora_city) <= 120),
  reputation_points integer not null default 0,
  created_at timestamptz not null default now()
);

-- Case-insensitive uniqueness: "Boricua" and "boricua" can't both exist.
create unique index profiles_username_key on public.profiles (lower(username));
create index profiles_home_municipio_id_idx on public.profiles (home_municipio_id);
create index profiles_current_municipio_id_idx on public.profiles (current_municipio_id);

-- Every auth user gets a profile row, so FKs from outages/votes/comments to
-- profiles always resolve.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
