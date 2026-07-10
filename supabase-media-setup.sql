-- Nuvelle Home Supabase setup
-- Run this once in Supabase Dashboard > SQL Editor.
-- It prepares storefront products, journal posts, storefront images, orders,
-- and a public storage bucket for product/journal media uploads.

create extension if not exists pgcrypto;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  sku text,
  name text not null default 'Untitled Product',
  slug text,
  price numeric default 0,
  category text default 'living-room',
  materials text,
  dimensions text,
  description text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.products
  add column if not exists sku text,
  add column if not exists name text,
  add column if not exists slug text,
  add column if not exists price numeric default 0,
  add column if not exists category text default 'living-room',
  add column if not exists subcategory text,
  add column if not exists style text,
  add column if not exists collection_slug text,
  add column if not exists materials text,
  add column if not exists dimensions text,
  add column if not exists description text,
  add column if not exists image_url text,
  add column if not exists gallery_images jsonb default '[]'::jsonb,
  add column if not exists video_url text,
  add column if not exists brand text default 'Nuvelle Home',
  add column if not exists sale_price numeric default 0,
  add column if not exists compare_at_price numeric default 0,
  add column if not exists stock_quantity integer default 0,
  add column if not exists is_clearance boolean default false,
  add column if not exists clearance_reason text,
  add column if not exists final_sale boolean default false,
  add column if not exists delivery_type text,
  add column if not exists allow_pickup boolean default true,
  add column if not exists allow_delivery boolean default true,
  add column if not exists status text default 'published',
  add column if not exists colors jsonb default '[]'::jsonb,
  add column if not exists features jsonb default '[]'::jsonb,
  add column if not exists delivery text,
  add column if not exists published boolean default true,
  add column if not exists featured boolean default false,
  add column if not exists in_stock boolean default true,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

create table if not exists public.site_assets (
  asset_key text primary key,
  url text not null,
  updated_at timestamptz default now()
);

create table if not exists public.journal_posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text unique not null,
  label text,
  excerpt text,
  hero_image text,
  images jsonb default '[]'::jsonb,
  sections jsonb default '[]'::jsonb,
  sort_order integer default 1,
  published boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.collections (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text unique not null,
  date_label text,
  excerpt text,
  body text,
  hero_image text,
  gallery_images jsonb default '[]'::jsonb,
  sections jsonb default '[]'::jsonb,
  category text default 'living-room',
  sort_order integer default 1,
  published boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text,
  customer_email text,
  customer_phone text,
  delivery_address text,
  items jsonb default '[]'::jsonb,
  subtotal numeric default 0,
  total numeric default 0,
  currency text default 'USD',
  provider text,
  payment_reference text,
  payment_status text default 'pending',
  status text default 'Pending',
  created_at timestamptz default now()
);

alter table public.orders
  add column if not exists delivery_method text,
  add column if not exists delivery_zip text,
  add column if not exists preferred_date date,
  add column if not exists delivery_fee numeric default 0,
  add column if not exists white_glove boolean default false,
  add column if not exists notes text,
  add column if not exists updated_at timestamptz default now();

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  name text,
  email text unique,
  total_orders integer default 0,
  total_spend numeric default 0,
  created_at timestamptz default now()
);

create table if not exists public.site_settings (
  setting_key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz default now()
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id text not null,
  sender text not null default 'customer',
  customer_name text,
  customer_email text,
  message text not null,
  page_url text,
  read_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  role text default 'owner',
  created_at timestamptz default now()
);

-- After creating the Supabase Auth user, update this email if Axel uses another login.
insert into public.admin_users (user_id, email, role)
select id, email, 'owner'
from auth.users
where email = 'nuvellehomedecor@gmail.com'
on conflict (user_id) do update set email = excluded.email, role = excluded.role;

insert into storage.buckets (id, name, public)
values ('product-media', 'product-media', true)
on conflict (id) do update set public = true;

alter table public.products enable row level security;
alter table public.site_assets enable row level security;
alter table public.journal_posts enable row level security;
alter table public.collections enable row level security;
alter table public.orders enable row level security;
alter table public.customers enable row level security;
alter table public.site_settings enable row level security;
alter table public.chat_messages enable row level security;
alter table public.admin_users enable row level security;

drop policy if exists "Admins can read admin users" on public.admin_users;
create policy "Admins can read admin users"
on public.admin_users for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "Public read published products" on public.products;
create policy "Public read published products"
on public.products for select
using (published is not false);

drop policy if exists "Authenticated manage products" on public.products;
drop policy if exists "Admins manage products" on public.products;
create policy "Admins manage products"
on public.products for all
to authenticated
using (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));

drop policy if exists "Public read site assets" on public.site_assets;
create policy "Public read site assets"
on public.site_assets for select
using (true);

drop policy if exists "Authenticated manage site assets" on public.site_assets;
drop policy if exists "Admins manage site assets" on public.site_assets;
create policy "Admins manage site assets"
on public.site_assets for all
to authenticated
using (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));

drop policy if exists "Public read published journal posts" on public.journal_posts;
create policy "Public read published journal posts"
on public.journal_posts for select
using (published is true);

drop policy if exists "Authenticated manage journal posts" on public.journal_posts;
drop policy if exists "Admins manage journal posts" on public.journal_posts;
create policy "Admins manage journal posts"
on public.journal_posts for all
to authenticated
using (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));

drop policy if exists "Public read published collections" on public.collections;
create policy "Public read published collections"
on public.collections for select
using (published is true);

drop policy if exists "Authenticated manage collections" on public.collections;
drop policy if exists "Admins manage collections" on public.collections;
create policy "Admins manage collections"
on public.collections for all
to authenticated
using (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));

drop policy if exists "Authenticated read orders" on public.orders;
drop policy if exists "Admins read orders" on public.orders;
create policy "Admins read orders"
on public.orders for select
to authenticated
using (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));

drop policy if exists "Authenticated manage orders" on public.orders;
drop policy if exists "Admins manage orders" on public.orders;
create policy "Admins manage orders"
on public.orders for all
to authenticated
using (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));

drop policy if exists "Authenticated read customers" on public.customers;
drop policy if exists "Admins read customers" on public.customers;
create policy "Admins read customers"
on public.customers for select
to authenticated
using (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));

drop policy if exists "Authenticated manage customers" on public.customers;
drop policy if exists "Admins manage customers" on public.customers;
create policy "Admins manage customers"
on public.customers for all
to authenticated
using (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));

drop policy if exists "Public read delivery settings" on public.site_settings;
create policy "Public read delivery settings"
on public.site_settings for select
using (setting_key in ('delivery_rules', 'showcase_images'));

drop policy if exists "Admins manage site settings" on public.site_settings;
create policy "Admins manage site settings"
on public.site_settings for all
to authenticated
using (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));

drop policy if exists "Admins read chat messages" on public.chat_messages;
create policy "Admins read chat messages"
on public.chat_messages for select
to authenticated
using (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));

drop policy if exists "Admins manage chat messages" on public.chat_messages;
create policy "Admins manage chat messages"
on public.chat_messages for all
to authenticated
using (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));

drop policy if exists "Public read product media" on storage.objects;
create policy "Public read product media"
on storage.objects for select
using (bucket_id = 'product-media');

drop policy if exists "Authenticated upload product media" on storage.objects;
drop policy if exists "Admins upload product media" on storage.objects;
create policy "Admins upload product media"
on storage.objects for insert
to authenticated
with check (bucket_id = 'product-media' and exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));

drop policy if exists "Authenticated update product media" on storage.objects;
drop policy if exists "Admins update product media" on storage.objects;
create policy "Admins update product media"
on storage.objects for update
to authenticated
using (bucket_id = 'product-media' and exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()))
with check (bucket_id = 'product-media' and exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));

drop policy if exists "Authenticated delete product media" on storage.objects;
drop policy if exists "Admins delete product media" on storage.objects;
create policy "Admins delete product media"
on storage.objects for delete
to authenticated
using (bucket_id = 'product-media' and exists (select 1 from public.admin_users admins where admins.user_id = auth.uid()));
