-- Run expire_stale_outages() every 15 minutes with pg_cron.
create extension if not exists pg_cron with schema pg_catalog;

select cron.schedule(
  'expire-stale-outages',
  '*/15 * * * *',
  'select public.expire_stale_outages()'
);
