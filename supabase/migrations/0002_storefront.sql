-- Storefront: cover photo and AI ad image.
-- Run in the Supabase SQL editor after 0001_init.sql.

alter table public.profiles
  add column if not exists cover_url text;

alter table public.pacas
  add column if not exists ad_url text;
