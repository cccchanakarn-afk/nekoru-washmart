-- ============================================================
-- Admin role + RLS policies for write access from admin.html
-- Run this in Supabase SQL Editor AFTER schema.sql
-- ============================================================

-- Table that lists which auth.users are admins
create table if not exists public.admin_users (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  email      text,
  added_at   timestamptz not null default now()
);

alter table public.admin_users enable row level security;

drop policy if exists "admins read admin_users" on public.admin_users;
create policy "admins read admin_users"
  on public.admin_users for select
  using (auth.uid() in (select user_id from public.admin_users));

-- Helper: is the caller an admin?
create or replace function public.is_admin()
returns boolean language sql security definer set search_path = public as $$
  select exists (select 1 from public.admin_users where user_id = auth.uid())
$$;

-- ----- Branches: admins write -----
drop policy if exists "admins write branches" on public.branches;
create policy "admins write branches"
  on public.branches for all
  using (public.is_admin())
  with check (public.is_admin());

-- Admins read all branches (including closed, for editing)
drop policy if exists "admins read all branches" on public.branches;
create policy "admins read all branches"
  on public.branches for select
  using (public.is_admin());

-- ----- Articles: admins write + read drafts -----
drop policy if exists "admins write articles" on public.articles;
create policy "admins write articles"
  on public.articles for all
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "admins read all articles" on public.articles;
create policy "admins read all articles"
  on public.articles for select
  using (public.is_admin());

-- ----- News & events -----
drop policy if exists "admins write news" on public.news_events;
create policy "admins write news"
  on public.news_events for all
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "admins read all news" on public.news_events;
create policy "admins read all news"
  on public.news_events for select
  using (public.is_admin());

-- ----- FAQs -----
drop policy if exists "admins write faqs" on public.faqs;
create policy "admins write faqs"
  on public.faqs for all
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "admins read all faqs" on public.faqs;
create policy "admins read all faqs"
  on public.faqs for select
  using (public.is_admin());

-- ----- Contacts: admins read + mark handled (already public insert) -----
drop policy if exists "admins read contacts" on public.contacts;
create policy "admins read contacts"
  on public.contacts for select
  using (public.is_admin());

drop policy if exists "admins update contacts" on public.contacts;
create policy "admins update contacts"
  on public.contacts for update
  using (public.is_admin())
  with check (public.is_admin());

-- ----- Franchise inquiries: admins read -----
drop policy if exists "admins read franchise" on public.franchise_inquiries;
create policy "admins read franchise"
  on public.franchise_inquiries for select
  using (public.is_admin());

drop policy if exists "admins update franchise" on public.franchise_inquiries;
create policy "admins update franchise"
  on public.franchise_inquiries for update
  using (public.is_admin())
  with check (public.is_admin());

-- ----- Career applications: admins read -----
drop policy if exists "admins read careers" on public.career_applications;
create policy "admins read careers"
  on public.career_applications for select
  using (public.is_admin());

drop policy if exists "admins update careers" on public.career_applications;
create policy "admins update careers"
  on public.career_applications for update
  using (public.is_admin())
  with check (public.is_admin());

-- ============================================================
-- Bootstrap the FIRST admin
-- After signing up at /admin.html (Sign up tab), run this with your email:
--
--   insert into public.admin_users (user_id, email)
--   select id, email from auth.users where email = 'YOU@EXAMPLE.COM'
--   on conflict do nothing;
--
-- After that, future admins can be added from admin UI or here.
-- ============================================================
