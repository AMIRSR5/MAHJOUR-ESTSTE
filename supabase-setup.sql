-- =====================================================
-- Mahjour Estate — Supabase setup
-- Run once: Supabase Dashboard → SQL Editor → New query → paste → Run
-- =====================================================

-- ---------- Tables ----------
create table if not exists public.settings (
  key   text primary key,
  value jsonb not null default '{}'::jsonb
);

create table if not exists public.categories (
  id      uuid primary key default gen_random_uuid(),
  name    text not null,
  icon    text default '',
  image_url text default '',
  sort    int  not null default 0,
  active  boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.listings (
  id          uuid primary key default gen_random_uuid(),
  code        bigint generated always as identity (start with 1001),
  category_id uuid references public.categories(id) on delete set null,
  title       text not null,
  description text default '',
  price       bigint,            -- price / deposit (Toman)
  rent        bigint,            -- monthly rent (Toman), optional
  price_text  text default '',   -- optional override, e.g. "توافقی"
  location    text default '',
  area_m2     int,
  rooms       int,
  images      text[] not null default '{}',
  deal_mode   text not null default 'default',  -- default | call | chat | both
  featured    boolean not null default false,
  active      boolean not null default true,
  sort        int not null default 0,
  created_at  timestamptz not null default now()
);

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- for projects created before category photos existed (safe to run again):
alter table public.categories add column if not exists image_url text default '';

create index if not exists listings_cat_idx on public.listings(category_id);

-- ---------- Admin check ----------
create or replace function public.is_admin()
returns boolean language sql security definer stable
set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- ---------- Row Level Security ----------
alter table public.settings   enable row level security;
alter table public.categories enable row level security;
alter table public.listings   enable row level security;
alter table public.admins     enable row level security;

drop policy if exists "settings read"   on public.settings;
drop policy if exists "settings write"  on public.settings;
drop policy if exists "cats read"       on public.categories;
drop policy if exists "cats write"      on public.categories;
drop policy if exists "listings read"   on public.listings;
drop policy if exists "listings write"  on public.listings;
drop policy if exists "admins self"     on public.admins;

create policy "settings read"  on public.settings   for select using (true);
create policy "settings write" on public.settings   for all    using (public.is_admin()) with check (public.is_admin());

create policy "cats read"      on public.categories for select using (active or public.is_admin());
create policy "cats write"     on public.categories for all    using (public.is_admin()) with check (public.is_admin());

create policy "listings read"  on public.listings   for select using (active or public.is_admin());
create policy "listings write" on public.listings   for all    using (public.is_admin()) with check (public.is_admin());

create policy "admins self"    on public.admins     for select using (user_id = auth.uid());

-- ---------- Storage (images) ----------
insert into storage.buckets (id, name, public)
values ('estate', 'estate', true)
on conflict (id) do nothing;

drop policy if exists "estate public read"  on storage.objects;
drop policy if exists "estate admin insert" on storage.objects;
drop policy if exists "estate admin update" on storage.objects;
drop policy if exists "estate admin delete" on storage.objects;

create policy "estate public read"  on storage.objects for select using (bucket_id = 'estate');
create policy "estate admin insert" on storage.objects for insert with check (bucket_id = 'estate' and public.is_admin());
create policy "estate admin update" on storage.objects for update using (bucket_id = 'estate' and public.is_admin());
create policy "estate admin delete" on storage.objects for delete using (bucket_id = 'estate' and public.is_admin());

-- ---------- Starter categories ----------
insert into public.categories (name, icon, sort)
select v.name, v.icon, v.sort from (values
  ('باغ',            '🌳', 1),
  ('ویلا',           '🏡', 2),
  ('خانه',           '🏠', 3),
  ('اجاره',          '🔑', 4),
  ('رهن',            '📄', 5),
  ('خرید',           '💼', 6),
  ('نمایشگاه ماشین', '🚗', 7)
) as v(name, icon, sort)
where not exists (select 1 from public.categories);

-- =====================================================
-- STEP 2 (after you create your admin user in
-- Authentication → Users → Add user, with email+password):
-- replace the email below and run this one line:
--
-- insert into public.admins (user_id)
-- select id from auth.users where email = 'YOUR_EMAIL@example.com';
-- =====================================================
