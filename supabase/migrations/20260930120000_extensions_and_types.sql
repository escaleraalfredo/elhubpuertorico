-- PostGIS for municipio/barrio boundaries and point-in-polygon lookups.
-- Installed into the `extensions` schema per Supabase convention, so PostGIS
-- types and functions are referenced as extensions.* below.
create schema if not exists extensions;
create extension if not exists postgis with schema extensions;

create type public.outage_type as enum ('power', 'water');

-- Only set for water outages. 'none' = no water service at all.
create type public.water_issue as enum ('none', 'low_pressure', 'dirty');

create type public.outage_status as enum ('active', 'restored', 'expired');

create type public.outage_vote_type as enum ('confirm', 'dispute', 'restored');
