create table public.outages (
  id bigint generated always as identity primary key,
  barrio_id bigint not null references public.barrios (id),
  municipio_id bigint not null references public.municipios (id),
  type public.outage_type not null,
  water_issue public.water_issue,
  status public.outage_status not null default 'active',
  started_at timestamptz not null default now(),
  resolved_at timestamptz,
  created_by uuid references public.profiles (id) on delete set null,
  -- Maintained by triggers on outage_votes; not writable by clients.
  confirm_count integer not null default 0 check (confirm_count >= 0),
  dispute_count integer not null default 0 check (dispute_count >= 0),
  restore_count integer not null default 0 check (restore_count >= 0),
  -- municipio_id must be the barrio's municipio.
  foreign key (barrio_id, municipio_id) references public.barrios (id, municipio_id),
  -- water_issue is set for water outages and only for them.
  check ((type = 'water') = (water_issue is not null)),
  check ((status = 'active') = (resolved_at is null))
);

-- At most one active outage per barrio and type. Also the ON CONFLICT target
-- report_outage uses to merge concurrent reports.
create unique index outages_one_active_per_barrio_type
  on public.outages (barrio_id, type)
  where status = 'active';

-- Active outages by municipio (main map/list query).
create index outages_active_by_municipio_idx
  on public.outages (municipio_id, started_at desc)
  where status = 'active';

-- Outage history by barrio.
create index outages_barrio_id_started_at_idx on public.outages (barrio_id, started_at desc);
create index outages_created_by_idx on public.outages (created_by);

create table public.outage_votes (
  id bigint generated always as identity primary key,
  outage_id bigint not null references public.outages (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  vote public.outage_vote_type not null,
  created_at timestamptz not null default now(),
  unique (outage_id, user_id, vote)
);

-- Latest vote per outage, for expiry.
create index outage_votes_outage_id_created_at_idx on public.outage_votes (outage_id, created_at desc);
create index outage_votes_user_id_idx on public.outage_votes (user_id);

create table public.comments (
  id bigint generated always as identity primary key,
  outage_id bigint not null references public.outages (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  parent_id bigint,
  body text not null check (char_length(btrim(body)) between 1 and 2000),
  created_at timestamptz not null default now(),
  unique (id, outage_id),
  -- A reply must belong to the same outage as its parent. Deleting a parent
  -- keeps the replies and turns them into top-level comments.
  foreign key (parent_id, outage_id)
    references public.comments (id, outage_id)
    on delete set null (parent_id),
  check (parent_id is distinct from id)
);

create index comments_outage_id_created_at_idx on public.comments (outage_id, created_at);
create index comments_parent_id_idx on public.comments (parent_id);
create index comments_user_id_idx on public.comments (user_id);
