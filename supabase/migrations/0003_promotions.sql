-- Promotion kinds for store Pro.
-- Run in the Supabase SQL editor after 0002_storefront.sql.

alter table public.promotions
  add column if not exists kind text not null default 'discount';

alter table public.promotions
  drop constraint if exists promotions_kind_check;

alter table public.promotions
  add constraint promotions_kind_check
  check (kind in ('discount', 'bundle', 'other'));

alter table public.promotions
  add column if not exists bundle_qty integer;
