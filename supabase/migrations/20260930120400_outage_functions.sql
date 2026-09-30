-- Keep outages.{confirm,dispute,restore}_count in sync with outage_votes.
-- Increments rather than recounts: under concurrent votes, `x = x + 1` re-reads
-- the locked row, while a COUNT(*) subquery could miss a concurrent vote.
create function public.sync_outage_vote_counts()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    update public.outages
    set confirm_count = confirm_count - (old.vote = 'confirm')::int,
        dispute_count = dispute_count - (old.vote = 'dispute')::int,
        restore_count = restore_count - (old.vote = 'restored')::int
    where id = old.outage_id;
  end if;

  if tg_op in ('INSERT', 'UPDATE') then
    update public.outages
    set confirm_count = confirm_count + (new.vote = 'confirm')::int,
        dispute_count = dispute_count + (new.vote = 'dispute')::int,
        restore_count = restore_count + (new.vote = 'restored')::int
    where id = new.outage_id;
  end if;

  return null;
end;
$$;

create trigger outage_votes_sync_counts
  after insert or delete or update of vote, outage_id on public.outage_votes
  for each row execute function public.sync_outage_vote_counts();

-- Report an outage at the caller's location. The point is only used to find the
-- barrio and is never written to a table. Error messages deliberately don't
-- include the coordinates, since errors end up in logs.
create function public.report_outage(
  lat double precision,
  lng double precision,
  type public.outage_type,
  water_issue public.water_issue default null
)
returns public.outages
language plpgsql
security definer
set search_path = ''
as $$
-- Parameters `type` and `water_issue` share names with outages columns. Bare names
-- resolve to columns; the parameters are always referenced as report_outage.<name>.
#variable_conflict use_column
declare
  v_user_id uuid := auth.uid();
  v_barrio_id bigint;
  v_municipio_id bigint;
  v_outage public.outages;
begin
  if v_user_id is null then
    raise exception 'Must be signed in to report an outage' using errcode = '42501';
  end if;

  if report_outage.type is null then
    raise exception 'Outage type is required' using errcode = '22004';
  end if;

  if lat is null or lng is null
     or lat not between -90 and 90
     or lng not between -180 and 180 then
    raise exception 'Invalid coordinates' using errcode = '22023';
  end if;

  if report_outage.type = 'power' and report_outage.water_issue is not null then
    raise exception 'water_issue only applies to water outages' using errcode = '22023';
  end if;

  select b.id, b.municipio_id
  into v_barrio_id, v_municipio_id
  from public.barrios b
  where extensions.st_contains(
    b.boundary::extensions.geometry,
    extensions.st_setsrid(extensions.st_makepoint(lng, lat), 4326)
  )
  limit 1;

  if v_barrio_id is null then
    raise exception 'Location is not inside a known barrio' using errcode = 'P0002';
  end if;

  -- Find or create the active outage. The partial unique index makes concurrent
  -- first reports converge on one row; retry covers the rare case where the
  -- conflicting outage stops being active between the insert and the select.
  for attempt in 1..3 loop
    insert into public.outages (barrio_id, municipio_id, type, water_issue, created_by)
    values (
      v_barrio_id,
      v_municipio_id,
      report_outage.type,
      case when report_outage.type = 'water' then coalesce(report_outage.water_issue, 'none') end,
      v_user_id
    )
    on conflict (barrio_id, type) where status = 'active' do nothing
    returning * into v_outage;

    exit when v_outage.id is not null;

    select * into v_outage
    from public.outages o
    where o.barrio_id = v_barrio_id
      and o.type = report_outage.type
      and o.status = 'active';

    exit when v_outage.id is not null;
  end loop;

  if v_outage.id is null then
    raise exception 'Could not record outage, please retry' using errcode = '40001';
  end if;

  insert into public.outage_votes (outage_id, user_id, vote)
  values (v_outage.id, v_user_id, 'confirm')
  on conflict (outage_id, user_id, vote) do nothing;

  -- Re-read so the returned counts include this vote.
  select * into v_outage from public.outages o where o.id = v_outage.id;
  return v_outage;
end;
$$;

-- Mark active outages with no new votes in the last 6 hours as expired.
-- Returns how many were expired. Scheduled with pg_cron in a later migration.
create function public.expire_stale_outages()
returns integer
language sql
security definer
set search_path = ''
as $$
  with expired as (
    update public.outages o
    set status = 'expired',
        resolved_at = now()
    where o.status = 'active'
      and o.started_at < now() - interval '6 hours'
      and not exists (
        select 1
        from public.outage_votes v
        where v.outage_id = o.id
          and v.created_at >= now() - interval '6 hours'
      )
    returning 1
  )
  select count(*)::integer from expired;
$$;

-- Supabase grants EXECUTE on new public functions to anon and authenticated.
revoke all on function public.report_outage(double precision, double precision, public.outage_type, public.water_issue)
  from public, anon, authenticated;
grant execute on function public.report_outage(double precision, double precision, public.outage_type, public.water_issue)
  to authenticated;

revoke all on function public.expire_stale_outages() from public, anon, authenticated;
grant execute on function public.expire_stale_outages() to service_role;

revoke all on function public.sync_outage_vote_counts() from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
