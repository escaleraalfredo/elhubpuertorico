-- Row level security on every table, plus column-level grants.
--
-- RLS controls which rows a user can touch; the grants control which columns.
-- Without them a user could, for example, set their own reputation_points or
-- an outage's vote counts through a normal UPDATE on a row they own.

alter table public.municipios enable row level security;
alter table public.barrios enable row level security;
alter table public.profiles enable row level security;
alter table public.outages enable row level security;
alter table public.outage_votes enable row level security;
alter table public.comments enable row level security;

-- Reset Supabase's default grants (ALL to anon/authenticated), then grant exactly what's needed.
revoke all on public.municipios, public.barrios, public.profiles,
  public.outages, public.outage_votes, public.comments
  from anon, authenticated;

-- municipios / barrios: public reference data, read-only for clients.
grant select on public.municipios, public.barrios to anon, authenticated;

create policy "Municipios are publicly readable"
  on public.municipios for select
  to anon, authenticated
  using (true);

create policy "Barrios are publicly readable"
  on public.barrios for select
  to anon, authenticated
  using (true);

-- profiles: publicly readable so usernames/avatars can be shown on outages and comments.
grant select on public.profiles to anon, authenticated;
grant insert (id, username, display_name, avatar_url, home_municipio_id, current_municipio_id, diaspora_city)
  on public.profiles to authenticated;
grant update (username, display_name, avatar_url, home_municipio_id, current_municipio_id, diaspora_city)
  on public.profiles to authenticated;
grant delete on public.profiles to authenticated;

create policy "Profiles are publicly readable"
  on public.profiles for select
  to anon, authenticated
  using (true);

create policy "Users can create their own profile"
  on public.profiles for insert
  to authenticated
  with check (id = (select auth.uid()));

create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "Users can delete their own profile"
  on public.profiles for delete
  to authenticated
  using (id = (select auth.uid()));

-- outages: status, timestamps and counts are server-managed.
grant select on public.outages to anon, authenticated;
grant insert (barrio_id, municipio_id, type, water_issue, created_by) on public.outages to authenticated;
grant update (water_issue) on public.outages to authenticated;
grant delete on public.outages to authenticated;

create policy "Outages are publicly readable"
  on public.outages for select
  to anon, authenticated
  using (true);

create policy "Authenticated users can create outages as themselves"
  on public.outages for insert
  to authenticated
  with check (created_by = (select auth.uid()));

create policy "Users can update their own outages"
  on public.outages for update
  to authenticated
  using (created_by = (select auth.uid()))
  with check (created_by = (select auth.uid()));

create policy "Users can delete their own outages"
  on public.outages for delete
  to authenticated
  using (created_by = (select auth.uid()));

-- outage_votes: a user can change the kind of a vote but not move it to another outage.
grant select on public.outage_votes to anon, authenticated;
grant insert (outage_id, user_id, vote) on public.outage_votes to authenticated;
grant update (vote) on public.outage_votes to authenticated;
grant delete on public.outage_votes to authenticated;

create policy "Votes are publicly readable"
  on public.outage_votes for select
  to anon, authenticated
  using (true);

create policy "Authenticated users can vote as themselves"
  on public.outage_votes for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy "Users can update their own votes"
  on public.outage_votes for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "Users can delete their own votes"
  on public.outage_votes for delete
  to authenticated
  using (user_id = (select auth.uid()));

-- comments: only the body is editable.
grant select on public.comments to anon, authenticated;
grant insert (outage_id, user_id, parent_id, body) on public.comments to authenticated;
grant update (body) on public.comments to authenticated;
grant delete on public.comments to authenticated;

create policy "Comments are publicly readable"
  on public.comments for select
  to anon, authenticated
  using (true);

create policy "Authenticated users can comment as themselves"
  on public.comments for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy "Users can update their own comments"
  on public.comments for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "Users can delete their own comments"
  on public.comments for delete
  to authenticated
  using (user_id = (select auth.uid()));
