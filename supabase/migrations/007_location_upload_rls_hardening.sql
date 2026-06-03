drop policy if exists "latest_locations_owner_registered_device_update" on public.latest_locations;

create policy "latest_locations_owner_registered_device_update" on public.latest_locations
for update using (
  profile_id = auth.uid()
) with check (
  profile_id = auth.uid()
  and exists (
    select 1 from public.devices d
    where d.id = latest_locations.device_id
      and d.profile_id = auth.uid()
  )
);

comment on policy "latest_locations_owner_registered_device_update" on public.latest_locations is
  'Allows an owner to replace their latest location row while still requiring the new device_id to be one of their registered devices. This avoids blocking native upload when early rows predate device_id backfill.';
