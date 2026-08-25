-- Run this in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'rep' check (role in ('rep','manager','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.visits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  rep_name text not null,
  visit_date date not null,
  customer text not null,
  location text,
  customer_type text,
  contact text,
  contact_role text,
  purpose text not null,
  outcome text not null,
  opportunity_value numeric not null default 0,
  products text[] not null default '{}',
  notes text,
  next_action text not null,
  followup_date date,
  support_needed text,
  photo_path text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.visits enable row level security;

create or replace function public.is_manager()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('manager','admin')
  );
$$;

-- Profiles
create policy "users read own profile" on public.profiles
for select using (id = auth.uid() or public.is_manager());

create policy "users update own profile" on public.profiles
for update using (id = auth.uid()) with check (id = auth.uid());

create policy "users insert own profile" on public.profiles
for insert with check (id = auth.uid());

-- Visits: reps see/edit their own; managers/admins see all.
create policy "read visits" on public.visits
for select using (user_id = auth.uid() or public.is_manager());

create policy "insert own visits" on public.visits
for insert with check (user_id = auth.uid());

create policy "update visits" on public.visits
for update using (user_id = auth.uid() or public.is_manager())
with check (user_id = auth.uid() or public.is_manager());

create policy "delete visits" on public.visits
for delete using (user_id = auth.uid() or public.is_manager());

-- Automatically create a profile when someone signs up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)), 'rep')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Photo bucket. RLS policies below assume a PRIVATE bucket named visit-photos.
insert into storage.buckets (id, name, public)
values ('visit-photos','visit-photos',false)
on conflict (id) do update set public = false;

create policy "upload own visit photos" on storage.objects
for insert to authenticated
with check (bucket_id = 'visit-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "read visit photos" on storage.objects
for select to authenticated
using (
  bucket_id = 'visit-photos'
  and ((storage.foldername(name))[1] = auth.uid()::text or public.is_manager())
);

create policy "delete own visit photos" on storage.objects
for delete to authenticated
using (
  bucket_id = 'visit-photos'
  and ((storage.foldername(name))[1] = auth.uid()::text or public.is_manager())
);
