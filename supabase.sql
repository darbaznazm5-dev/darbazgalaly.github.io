-- TECHZONE SUPABASE BASE SCHEMA
-- Use on a NEW/EMPTY project, or reconcile with your existing schema before running.
create extension if not exists pgcrypto;

create table if not exists public.categories(
 id uuid primary key default gen_random_uuid(),
 name text not null,
 slug text unique,
 image_url text,
 is_active boolean not null default true,
 created_at timestamptz not null default now()
);

create table if not exists public.products(
 id uuid primary key default gen_random_uuid(),
 category_id uuid references public.categories(id) on delete set null,
 name text not null,
 slug text unique,
 description text,
 brand text,
 price numeric(14,2) not null default 0,
 compare_price numeric(14,2),
 image_url text,
 images jsonb not null default '[]'::jsonb,
 stock integer not null default 0,
 sku text,
 quality text default 'Original',
 warranty text,
 is_active boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table if not exists public.profiles(
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text,
 phone text,
 role text not null default 'customer' check(role in ('customer','admin')),
 created_at timestamptz not null default now()
);

create table if not exists public.orders(
 id uuid primary key default gen_random_uuid(),
 user_id uuid references auth.users(id) on delete set null,
 customer_name text,
 phone text,
 city text,
 address text,
 payment_method text not null default 'cod',
 status text not null default 'pending',
 total_amount numeric(14,2) not null default 0,
 created_at timestamptz not null default now()
);

create table if not exists public.order_items(
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id) on delete cascade,
 product_id uuid references public.products(id) on delete set null,
 product_name text not null,
 quantity integer not null check(quantity > 0),
 unit_price numeric(14,2) not null,
 total_price numeric(14,2) not null
);

create table if not exists public.reviews(
 id uuid primary key default gen_random_uuid(),
 product_id uuid not null references public.products(id) on delete cascade,
 user_id uuid references auth.users(id) on delete cascade,
 rating integer not null check(rating between 1 and 5),
 comment text,
 created_at timestamptz not null default now(),
 unique(product_id,user_id)
);

create table if not exists public.contact_messages(
 id uuid primary key default gen_random_uuid(),
 name text,
 email text,
 phone text,
 message text,
 created_at timestamptz not null default now()
);

alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.profiles enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.reviews enable row level security;
alter table public.contact_messages enable row level security;

-- Public catalog
drop policy if exists "public read categories" on public.categories;
create policy "public read categories" on public.categories for select to anon, authenticated using (is_active = true);

drop policy if exists "public read products" on public.products;
create policy "public read products" on public.products for select to anon, authenticated using (is_active = true);

-- Profile: user can read own profile
drop policy if exists "own profile read" on public.profiles;
create policy "own profile read" on public.profiles for select to authenticated using (id = auth.uid());

-- Customer orders
drop policy if exists "customer create order" on public.orders;
create policy "customer create order" on public.orders for insert to anon, authenticated with check (user_id is null or user_id = auth.uid());

drop policy if exists "customer read own orders" on public.orders;
create policy "customer read own orders" on public.orders for select to authenticated using (user_id = auth.uid());

drop policy if exists "customer create order items" on public.order_items;
create policy "customer create order items" on public.order_items for insert to anon, authenticated with check (true);

drop policy if exists "customer read own order items" on public.order_items;
create policy "customer read own order items" on public.order_items for select to authenticated using (
 exists(select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid())
);

-- Reviews
drop policy if exists "public read reviews" on public.reviews;
create policy "public read reviews" on public.reviews for select to anon, authenticated using (true);

drop policy if exists "signed users create reviews" on public.reviews;
create policy "signed users create reviews" on public.reviews for insert to authenticated with check (user_id = auth.uid());

-- Contact messages
drop policy if exists "public create contact messages" on public.contact_messages;
create policy "public create contact messages" on public.contact_messages for insert to anon, authenticated with check (true);

-- Admin policies using profiles.role
drop policy if exists "admin all categories" on public.categories;
create policy "admin all categories" on public.categories for all to authenticated using (
 exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')
) with check (
 exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')
);

drop policy if exists "admin all products" on public.products;
create policy "admin all products" on public.products for all to authenticated using (
 exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')
) with check (
 exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')
);

drop policy if exists "admin all orders" on public.orders;
create policy "admin all orders" on public.orders for all to authenticated using (
 exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')
) with check (
 exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')
);

drop policy if exists "admin all order items" on public.order_items;
create policy "admin all order items" on public.order_items for all to authenticated using (
 exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')
) with check (
 exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')
);

drop policy if exists "admin all profiles" on public.profiles;
create policy "admin all profiles" on public.profiles for all to authenticated using (
 exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')
) with check (
 exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')
);

-- Basic grants
grant select on public.categories, public.products, public.reviews to anon, authenticated;
grant insert on public.orders, public.order_items, public.contact_messages to anon, authenticated;
grant select on public.orders, public.order_items to authenticated;
grant select, insert on public.reviews to authenticated;
grant all on public.categories, public.products, public.orders, public.order_items, public.profiles to authenticated;

-- Create profile automatically after signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles(id, full_name)
  values(new.id, coalesce(new.raw_user_meta_data->>'full_name',''))
  on conflict(id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Seed categories
insert into public.categories(name,slug) values
('مۆبایل','mobile'),('کۆمپیوتەر و لەپتۆپ','laptop'),('گوێگر و ئاکسسوارات','audio'),
('سەعات','watch'),('گیمینگ','gaming'),('ماڵی زیرەک','smart-home')
on conflict(slug) do nothing;

-- After creating your admin user in Authentication, run:
-- update public.profiles set role='admin' where id='USER_UUID_HERE';
