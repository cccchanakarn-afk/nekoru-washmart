-- ============================================================
-- Admin management helpers
-- RPC functions callable from admin.html so admins can add/remove
-- other admins by email without needing direct SQL access.
-- Run this once in Supabase SQL Editor.
-- ============================================================

-- Add admin by email. Looks up auth.users to find the UID.
-- Returns: 'added' | 'already_admin' | 'user_not_found'
create or replace function public.add_admin_by_email(target_email text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_email   text;
begin
  if not public.is_admin() then
    raise exception 'Only admins can add admins';
  end if;
  -- case-insensitive email lookup
  select id, email into v_user_id, v_email
  from auth.users
  where lower(email) = lower(trim(target_email))
  limit 1;
  if v_user_id is null then
    return 'user_not_found';
  end if;
  if exists (select 1 from public.admin_users where user_id = v_user_id) then
    return 'already_admin';
  end if;
  insert into public.admin_users (user_id, email)
  values (v_user_id, v_email);
  return 'added';
end
$$;

-- Remove admin by user_id. Guards: cannot remove self, cannot remove last admin.
create or replace function public.remove_admin(target_user_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  if not public.is_admin() then
    raise exception 'Only admins can remove admins';
  end if;
  if target_user_id = auth.uid() then
    raise exception 'You cannot remove yourself';
  end if;
  select count(*) into v_count from public.admin_users;
  if v_count <= 1 then
    raise exception 'Cannot remove the last admin';
  end if;
  delete from public.admin_users where user_id = target_user_id;
  return 'removed';
end
$$;

-- Grants (functions in public are normally callable by anon/authenticated,
-- but make it explicit so RLS doesn't surprise us)
grant execute on function public.add_admin_by_email(text) to authenticated;
grant execute on function public.remove_admin(uuid)       to authenticated;
