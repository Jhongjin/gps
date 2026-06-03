alter table public.location_history
add column if not exists idempotency_key text;

create unique index if not exists location_history_profile_idempotency_idx
on public.location_history (profile_id, idempotency_key);

comment on column public.location_history.idempotency_key is 'Client-generated key, usually deviceId + sequence + recordedAt, used to dedupe native upload retries.';
