-- Paca GT initial schema (Shipaton)
-- Run in Supabase SQL editor or via supabase db push

create extension if not exists "pgcrypto";

-- Profiles (1:1 with auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text check (role is null or role in ('store', 'buyer')),
  display_name text,
  department text,
  phone_whatsapp text,
  logo_url text,
  brand_color text default '#1B5E20',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.pacas (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  description text,
  price_gtq numeric(10, 2) not null check (price_gtq >= 0),
  category text,
  size_mix text,
  photo_urls text[] not null default '{}',
  status text not null default 'draft'
    check (status in ('draft', 'active', 'sold')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists pacas_store_id_idx on public.pacas (store_id);
create index if not exists pacas_status_idx on public.pacas (status);

create table if not exists public.promotions (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.profiles (id) on delete cascade,
  paca_id uuid references public.pacas (id) on delete set null,
  title text not null,
  discount_label text,
  starts_at timestamptz,
  ends_at timestamptz,
  premium_only boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists promotions_store_id_idx on public.promotions (store_id);

create table if not exists public.share_logs (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.profiles (id) on delete cascade,
  paca_id uuid not null references public.pacas (id) on delete cascade,
  template text not null check (template in ('plain', 'branded')),
  created_at timestamptz not null default now()
);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- updated_at helper
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists pacas_updated_at on public.pacas;
create trigger pacas_updated_at
  before update on public.pacas
  for each row execute function public.set_updated_at();

-- RLS
alter table public.profiles enable row level security;
alter table public.pacas enable row level security;
alter table public.promotions enable row level security;
alter table public.share_logs enable row level security;

-- Profiles policies
drop policy if exists "Profiles are readable by authenticated" on public.profiles;
create policy "Profiles are readable by authenticated"
  on public.profiles for select
  to authenticated
  using (true);

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "Users insert own profile" on public.profiles;
create policy "Users insert own profile"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

-- Pacas policies
drop policy if exists "Anyone authenticated reads active pacas" on public.pacas;
create policy "Anyone authenticated reads active pacas"
  on public.pacas for select
  to authenticated
  using (status = 'active' or store_id = auth.uid());

drop policy if exists "Stores insert own pacas" on public.pacas;
create policy "Stores insert own pacas"
  on public.pacas for insert
  to authenticated
  with check (store_id = auth.uid());

drop policy if exists "Stores update own pacas" on public.pacas;
create policy "Stores update own pacas"
  on public.pacas for update
  to authenticated
  using (store_id = auth.uid())
  with check (store_id = auth.uid());

drop policy if exists "Stores delete own pacas" on public.pacas;
create policy "Stores delete own pacas"
  on public.pacas for delete
  to authenticated
  using (store_id = auth.uid());

-- Promotions: readable by authenticated (app gates premium_only via RevenueCat)
drop policy if exists "Authenticated read promotions" on public.promotions;
create policy "Authenticated read promotions"
  on public.promotions for select
  to authenticated
  using (true);

drop policy if exists "Stores manage own promotions" on public.promotions;
create policy "Stores manage own promotions"
  on public.promotions for all
  to authenticated
  using (store_id = auth.uid())
  with check (store_id = auth.uid());

-- Share logs
drop policy if exists "Stores read own share logs" on public.share_logs;
create policy "Stores read own share logs"
  on public.share_logs for select
  to authenticated
  using (store_id = auth.uid());

drop policy if exists "Stores insert own share logs" on public.share_logs;
create policy "Stores insert own share logs"
  on public.share_logs for insert
  to authenticated
  with check (store_id = auth.uid());

-- Storage buckets
insert into storage.buckets (id, name, public)
values ('paca-photos', 'paca-photos', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('store-logos', 'store-logos', true)
on conflict (id) do nothing;

drop policy if exists "Public read paca photos" on storage.objects;
create policy "Public read paca photos"
  on storage.objects for select
  using (bucket_id = 'paca-photos');

drop policy if exists "Owners upload paca photos" on storage.objects;
create policy "Owners upload paca photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'paca-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Owners update paca photos" on storage.objects;
create policy "Owners update paca photos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'paca-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Owners delete paca photos" on storage.objects;
create policy "Owners delete paca photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'paca-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Public read store logos" on storage.objects;
create policy "Public read store logos"
  on storage.objects for select
  using (bucket_id = 'store-logos');

drop policy if exists "Owners upload store logos" on storage.objects;
create policy "Owners upload store logos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'store-logos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Owners update store logos" on storage.objects;
create policy "Owners update store logos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'store-logos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Owners delete store logos" on storage.objects;
create policy "Owners delete store logos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'store-logos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
