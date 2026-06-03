create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  preferred_name text;
begin
  preferred_name := coalesce(
    nullif(new.raw_user_meta_data ->> 'display_name', ''),
    nullif(new.raw_user_meta_data ->> 'name', ''),
    nullif(split_part(new.email, '@', 1), ''),
    '새 사용자'
  );

  insert into public.profiles (
    id,
    display_name,
    avatar_url,
    is_minor
  )
  values (
    new.id,
    preferred_name,
    new.raw_user_meta_data ->> 'avatar_url',
    false
  )
  on conflict (id) do nothing;

  insert into public.ad_preferences (
    profile_id,
    personalized_ads_enabled,
    sensitive_categories_blocked,
    precise_location_ads_enabled
  )
  values (
    new.id,
    false,
    true,
    false
  )
  on conflict (profile_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

comment on function public.handle_new_auth_user() is 'Creates the public profile and default privacy-safe ad preferences for every new auth user.';
