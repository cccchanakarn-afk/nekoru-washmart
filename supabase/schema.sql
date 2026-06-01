-- ============================================================
-- Nekoru Washmart — Supabase schema
-- Run this in Supabase Studio → SQL Editor → New query
-- ============================================================

-- ---------- ENUMs ----------
do $$ begin
  create type contact_subject as enum (
    'general', 'machine_issue', 'franchise', 'careers', 'feedback'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type member_tier as enum ('kitten', 'kitty', 'tiger');
exception when duplicate_object then null; end $$;

do $$ begin
  create type branch_status as enum ('open', 'coming_soon', 'closed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type article_category as enum (
    'fabric_care', 'machine_usage', 'troubleshooting', 'tips', 'news'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type event_type as enum ('promo', 'news', 'event', 'announcement');
exception when duplicate_object then null; end $$;

-- ---------- 1. Contact form submissions ----------
create table if not exists public.contacts (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  phone        text not null,
  subject      contact_subject not null default 'general',
  message      text not null,
  consent      boolean not null default false,
  source       text default 'landing_page',
  user_agent   text,
  created_at   timestamptz not null default now(),
  handled_at   timestamptz,
  handled_note text
);
create index if not exists contacts_created_at_idx on public.contacts (created_at desc);

-- ---------- 2. Newsletter subscribers ----------
create table if not exists public.newsletter_subscribers (
  id           uuid primary key default gen_random_uuid(),
  email        text not null unique,
  line_id      text,
  consent      boolean not null default true,
  created_at   timestamptz not null default now(),
  unsubscribed_at timestamptz
);

-- ---------- 3. Members (loyalty) ----------
create table if not exists public.members (
  id           uuid primary key default gen_random_uuid(),
  auth_user_id uuid references auth.users(id) on delete set null,
  member_code  text not null unique,           -- e.g. 'NK-2026-8888-8888'
  full_name    text not null,
  phone        text not null unique,
  line_id      text,
  tier         member_tier not null default 'kitten',
  points       int not null default 0 check (points >= 0),
  total_spent  numeric(12,2) not null default 0,
  birthday     date,
  created_at   timestamptz not null default now(),
  last_active_at timestamptz not null default now()
);
create index if not exists members_phone_idx on public.members (phone);

create table if not exists public.member_points_log (
  id           bigserial primary key,
  member_id    uuid not null references public.members(id) on delete cascade,
  delta        int not null,                   -- +1 for earn, -10 for redeem, etc.
  reason       text not null,                  -- 'wash_dry_M', 'redeem_free_wash', ...
  branch_id    uuid,
  amount_thb   numeric(10,2),
  created_at   timestamptz not null default now()
);
create index if not exists points_log_member_idx on public.member_points_log (member_id, created_at desc);

-- ---------- 4. Branches ----------
create table if not exists public.branches (
  id              uuid primary key default gen_random_uuid(),
  slug            text not null unique,
  name_th         text not null,
  name_en         text,
  address_th      text not null,
  address_en      text,
  province        text,
  district        text,
  lat             double precision,
  lng             double precision,
  google_maps_url text,
  phone           text,
  status          branch_status not null default 'open',
  open_hours      text default '24h',          -- '24h' or '06:00–22:00'
  attendant_hours text,                        -- '08:00–18:00 (closed Wed)'
  features        jsonb not null default '{}'::jsonb,
                    -- e.g. { "parking": true, "wifi": true, "cctv": true,
                    --        "attendant": true, "drop_off": true }
  machines        jsonb not null default '{}'::jsonb,
                    -- e.g. { "M_17kg": 4, "L_27kg": 2 }
  cover_image_url text,
  opened_at       date,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists branches_status_idx on public.branches (status);
create index if not exists branches_province_idx on public.branches (province);

-- ---------- 5. Articles (blog) ----------
create table if not exists public.articles (
  id              uuid primary key default gen_random_uuid(),
  slug            text not null unique,
  category        article_category not null,
  title_th        text not null,
  title_en        text,
  excerpt_th      text,
  excerpt_en      text,
  content_md_th   text,
  content_md_en   text,
  cover_image_url text,
  read_minutes    int default 3,
  published_at    timestamptz,
  author          text,
  views           int not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists articles_published_idx on public.articles (published_at desc nulls last);
create index if not exists articles_category_idx on public.articles (category);

-- ---------- 6. News & events / promotions ----------
create table if not exists public.news_events (
  id              uuid primary key default gen_random_uuid(),
  type            event_type not null default 'news',
  badge           text,                        -- '🔥 ลดเฉพาะ', '🎉 สาขาใหม่'
  title_th        text not null,
  title_en        text,
  body_th         text,
  body_en         text,
  promo_code      text,                        -- 'NIGHT30'
  discount_label  text,                        -- '30% off'
  start_date      date,
  end_date        date,
  cover_image_url text,
  branch_ids      uuid[] default '{}',         -- empty = all branches
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);
create index if not exists news_events_active_idx on public.news_events (is_active, start_date desc);

-- ---------- 7. Franchise inquiries ----------
create table if not exists public.franchise_inquiries (
  id                uuid primary key default gen_random_uuid(),
  full_name         text not null,
  phone             text not null,
  email             text,
  line_id           text,
  budget_thb        numeric(12,2),
  province_interest text,
  message           text,
  status            text not null default 'new',  -- new | contacted | closed
  created_at        timestamptz not null default now()
);

-- ---------- 8. Career applications ----------
create table if not exists public.career_applications (
  id               uuid primary key default gen_random_uuid(),
  full_name        text not null,
  phone            text not null,
  email            text,
  position         text not null,                -- 'branch_attendant' | 'technician' | 'area_manager'
  province         text,
  resume_url       text,
  expected_salary  numeric(10,2),
  message          text,
  status           text not null default 'new',
  created_at       timestamptz not null default now()
);

-- ---------- 9. FAQ (admin-editable) ----------
create table if not exists public.faqs (
  id              uuid primary key default gen_random_uuid(),
  category        text not null,                -- machine_usage | machine_problems | fabric_care | troubleshooting | branches
  question_th     text not null,
  question_en     text,
  answer_th       text not null,
  answer_en       text,
  sort_order      int not null default 0,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);
create index if not exists faqs_category_idx on public.faqs (category, sort_order);

-- ============================================================
-- updated_at trigger helper
-- ============================================================
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$ begin
  create trigger trg_branches_updated_at before update on public.branches
    for each row execute function public.set_updated_at();
exception when duplicate_object then null; end $$;

do $$ begin
  create trigger trg_articles_updated_at before update on public.articles
    for each row execute function public.set_updated_at();
exception when duplicate_object then null; end $$;

-- ============================================================
-- Row Level Security
-- ============================================================
alter table public.contacts             enable row level security;
alter table public.newsletter_subscribers enable row level security;
alter table public.members              enable row level security;
alter table public.member_points_log    enable row level security;
alter table public.branches             enable row level security;
alter table public.articles             enable row level security;
alter table public.news_events          enable row level security;
alter table public.franchise_inquiries  enable row level security;
alter table public.career_applications  enable row level security;
alter table public.faqs                 enable row level security;

-- ----- Public READ for content tables (anyone can fetch published content) -----
drop policy if exists "public read open branches" on public.branches;
create policy "public read open branches"
  on public.branches for select
  using (status in ('open', 'coming_soon'));

drop policy if exists "public read published articles" on public.articles;
create policy "public read published articles"
  on public.articles for select
  using (published_at is not null and published_at <= now());

drop policy if exists "public read active news" on public.news_events;
create policy "public read active news"
  on public.news_events for select
  using (is_active = true);

drop policy if exists "public read active faqs" on public.faqs;
create policy "public read active faqs"
  on public.faqs for select
  using (is_active = true);

-- ----- Public INSERT (anonymous form submissions) -----
drop policy if exists "anyone can submit contact" on public.contacts;
create policy "anyone can submit contact"
  on public.contacts for insert
  with check (true);

drop policy if exists "anyone can subscribe newsletter" on public.newsletter_subscribers;
create policy "anyone can subscribe newsletter"
  on public.newsletter_subscribers for insert
  with check (true);

drop policy if exists "anyone can inquire franchise" on public.franchise_inquiries;
create policy "anyone can inquire franchise"
  on public.franchise_inquiries for insert
  with check (true);

drop policy if exists "anyone can apply career" on public.career_applications;
create policy "anyone can apply career"
  on public.career_applications for insert
  with check (true);

-- ----- Members: only the signed-in user sees their own row -----
drop policy if exists "members see own row" on public.members;
create policy "members see own row"
  on public.members for select
  using (auth.uid() = auth_user_id);

drop policy if exists "members update own row" on public.members;
create policy "members update own row"
  on public.members for update
  using (auth.uid() = auth_user_id);

drop policy if exists "members see own points log" on public.member_points_log;
create policy "members see own points log"
  on public.member_points_log for select
  using (
    member_id in (select id from public.members where auth_user_id = auth.uid())
  );

-- NOTE: writes to members / points_log / branches / articles / news_events
-- should be done from server-side code with the SERVICE ROLE key (never expose
-- that key to the browser). Admin UI: build a small protected /admin page later.

-- ============================================================
-- Seed: first branch (Ban Kluai Joho)
-- ============================================================
insert into public.branches
  (slug, name_th, name_en, address_th, province, district, status, open_hours, attendant_hours, features, google_maps_url)
values
  ('ban-kluai-joho',
   'สาขาบ้านกล้วย จอหอ',
   'Ban Kluai Joho',
   'สาขาบ้านกล้วย จอหอ ติด 7-Eleven',
   'นครราชสีมา',
   'จอหอ',
   'open',
   '24h',
   '08:00–18:00 (หยุดวันพุธ)',
   '{"parking": true, "wifi": true, "cctv": true, "attendant": true, "drop_off": true, "free_detergent": true, "ozone": true}'::jsonb,
   'https://maps.app.goo.gl/mRoWMWZua2StcYee7')
on conflict (slug) do nothing;
