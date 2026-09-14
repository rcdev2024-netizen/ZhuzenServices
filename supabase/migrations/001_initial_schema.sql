-- Service Operations API schema for Supabase.
-- Run this file in Supabase SQL Editor or with the Supabase CLI.

create extension if not exists pgcrypto;

create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists roles (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  permissions jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  password_hash text not null,
  full_name text,
  role_id uuid references roles(id) on delete set null,
  is_active boolean not null default true,
  last_logout_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists refresh_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  token_jti text not null unique,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists password_resets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  token_hash text not null,
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text,
  phone text,
  company text,
  address jsonb not null default '{}'::jsonb,
  notes text,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists assets (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references customers(id) on delete set null,
  name text not null,
  asset_type text,
  serial_number text,
  manufacturer text,
  model text,
  installed_at date,
  warranty_expires_at date,
  metadata jsonb not null default '{}'::jsonb,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Flexible records remain available for timeline, activity, and future
-- cross-module entries. The concrete domain tables are created in migration 002.
create table if not exists resource_records (
  id uuid primary key default gen_random_uuid(),
  resource_type text not null,
  parent_id uuid,
  created_by uuid references users(id) on delete set null,
  status text not null default 'draft',
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists resource_records_type_idx on resource_records(resource_type);
create index if not exists resource_records_parent_idx on resource_records(parent_id);
create index if not exists refresh_tokens_user_idx on refresh_tokens(user_id);
create index if not exists password_resets_user_idx on password_resets(user_id);

drop trigger if exists roles_updated_at on roles;
create trigger roles_updated_at before update on roles
for each row execute function set_updated_at();

drop trigger if exists users_updated_at on users;
create trigger users_updated_at before update on users
for each row execute function set_updated_at();

drop trigger if exists customers_updated_at on customers;
create trigger customers_updated_at before update on customers
for each row execute function set_updated_at();

drop trigger if exists assets_updated_at on assets;
create trigger assets_updated_at before update on assets
for each row execute function set_updated_at();

drop trigger if exists resource_records_updated_at on resource_records;
create trigger resource_records_updated_at before update on resource_records
for each row execute function set_updated_at();

alter table roles enable row level security;
alter table users enable row level security;
alter table refresh_tokens enable row level security;
alter table password_resets enable row level security;
alter table customers enable row level security;
alter table assets enable row level security;
alter table resource_records enable row level security;

-- The API uses the Supabase service-role key on the server. Do not expose it
-- to a browser. Add end-user RLS policies later if clients query Supabase directly.