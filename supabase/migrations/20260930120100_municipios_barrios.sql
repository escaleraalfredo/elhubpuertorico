-- Boundaries are MultiPolygons: several municipios (Vieques, Culebra, Cabo Rojo, ...)
-- and barrios include offshore islands, which a single Polygon can't represent.

create table public.municipios (
  id bigint generated always as identity primary key,
  name text not null unique,
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  centroid extensions.geography(Point, 4326) not null,
  boundary extensions.geography(MultiPolygon, 4326) not null
);

create table public.barrios (
  id bigint generated always as identity primary key,
  municipio_id bigint not null references public.municipios (id),
  name text not null,
  boundary extensions.geography(MultiPolygon, 4326) not null,
  -- Barrio names repeat across municipios (e.g. "Pueblo"), so unique per municipio only.
  unique (municipio_id, name),
  -- Target for the composite FK on outages that keeps barrio and municipio consistent.
  unique (id, municipio_id)
);

create index barrios_municipio_id_idx on public.barrios (municipio_id);

-- Spatial indexes. The geography GiST indexes serve distance/intersection queries
-- (ST_DWithin, ST_Intersects). ST_Contains only works on geometry, so report_outage
-- casts the barrio boundary; the expression index matches that cast.
create index municipios_boundary_idx on public.municipios using gist (boundary);
create index municipios_centroid_idx on public.municipios using gist (centroid);
create index barrios_boundary_idx on public.barrios using gist (boundary);
create index barrios_boundary_geom_idx on public.barrios using gist ((boundary::extensions.geometry));
