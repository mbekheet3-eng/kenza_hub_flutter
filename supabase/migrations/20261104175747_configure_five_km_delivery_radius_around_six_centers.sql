
alter table public.regions
  add column center_latitude numeric(10,7),
  add column center_longitude numeric(10,7),
  add column delivery_radius_km numeric(5,2) not null default 5.00;

alter table public.regions
  add constraint regions_center_coordinates_pair_check
    check ((center_latitude is null) = (center_longitude is null)),
  add constraint regions_center_latitude_range_check
    check (center_latitude is null or center_latitude between -90 and 90),
  add constraint regions_center_longitude_range_check
    check (center_longitude is null or center_longitude between -180 and 180),
  add constraint regions_delivery_radius_range_check
    check (delivery_radius_km between 0.10 and 50.00);

update public.regions as r
set center_latitude = v.latitude,
    center_longitude = v.longitude,
    delivery_radius_km = 5.00
from (values
  ('المعادي', 29.9680100::numeric, 31.2491400::numeric),
  ('الدقي', 30.0389000::numeric, 31.2125600::numeric),
  ('العجوزة', 30.0522200::numeric, 31.2155600::numeric),
  ('المهندسين', 30.0582400::numeric, 31.2017800::numeric),
  ('وسط البلد', 30.0475000::numeric, 31.2383000::numeric),
  ('المنيل', 29.9500000::numeric, 31.2333300::numeric)
) as v(name_ar, latitude, longitude)
where r.name_ar = v.name_ar
  and r.is_delivery_active = true;

do $$
declare
  configured_count integer;
begin
  select count(*) into configured_count
  from public.regions
  where is_delivery_active = true
    and center_latitude is not null
    and center_longitude is not null
    and delivery_radius_km = 5.00;

  if configured_count <> 6 then
    raise exception 'Expected 6 configured active delivery centers, found %', configured_count;
  end if;
end;
$$;

create or replace function public.is_delivery_location_covered(
  p_latitude numeric,
  p_longitude numeric
)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select
    case
      when p_latitude is null or p_longitude is null
        or p_latitude not between -90 and 90
        or p_longitude not between -180 and 180
      then false
      else exists (
        select 1
        from public.regions r
        where r.is_active = true
          and r.is_delivery_active = true
          and r.center_latitude is not null
          and r.center_longitude is not null
          and (
            6371.0088 * 2 * asin(
              sqrt(
                least(
                  1.0,
                  greatest(
                    0.0,
                    power(sin(radians((p_latitude - r.center_latitude)::double precision) / 2), 2)
                    + cos(radians(r.center_latitude::double precision))
                    * cos(radians(p_latitude::double precision))
                    * power(sin(radians((p_longitude - r.center_longitude)::double precision) / 2), 2)
                  )
                )
              )
            )
          ) <= r.delivery_radius_km
      )
    end;
$$;

revoke all on function public.is_delivery_location_covered(numeric, numeric) from public, anon, authenticated;
grant execute on function public.is_delivery_location_covered(numeric, numeric) to anon, authenticated;

comment on column public.regions.center_latitude is 'Approximate geographic center latitude used for the launch delivery radius.';
comment on column public.regions.center_longitude is 'Approximate geographic center longitude used for the launch delivery radius.';
comment on column public.regions.delivery_radius_km is 'Straight-line delivery coverage radius in kilometers around this region center.';
comment on function public.is_delivery_location_covered(numeric, numeric) is 'Returns true when coordinates fall within the configured straight-line delivery radius of any active delivery center.';
