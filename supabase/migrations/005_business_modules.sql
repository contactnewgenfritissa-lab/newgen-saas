-- New Gen SaaS v1 business modules. Safe to run after the initial schema and role permissions.
create extension if not exists pgcrypto;

create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique,
  owner_id uuid references public.profiles(id) on delete set null,
  phone text,
  email text,
  city text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists store_id uuid references public.stores(id) on delete set null;
alter table public.orders add column if not exists store_id uuid references public.stores(id) on delete set null;
alter table public.orders add column if not exists external_reference text;
alter table public.orders add column if not exists source text default 'manual';

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  store_id uuid references public.stores(id) on delete cascade,
  full_name text not null,
  phone text not null,
  alternate_phone text,
  city text,
  address text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(store_id, phone)
);

alter table public.orders add column if not exists customer_id uuid references public.customers(id) on delete set null;

create table if not exists public.shipping_companies (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  code text unique,
  phone text,
  website text,
  api_base_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.shipments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  shipping_company_id uuid references public.shipping_companies(id) on delete set null,
  tracking_number text unique,
  status text not null default 'draft',
  shipping_cost numeric(12,2) not null default 0,
  shipped_at timestamptz,
  delivered_at timestamptz,
  returned_at timestamptz,
  last_event text,
  updated_by uuid references public.profiles(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles(id) on delete set null,
  store_id uuid references public.stores(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  old_data jsonb,
  new_data jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text,
  type text not null default 'info',
  is_read boolean not null default false,
  link text,
  created_at timestamptz not null default now()
);

create table if not exists public.system_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);

create index if not exists idx_orders_store on public.orders(store_id);
create index if not exists idx_orders_assigned on public.orders(assigned_to);
create index if not exists idx_orders_status on public.orders(status);
create index if not exists idx_customers_store_phone on public.customers(store_id, phone);
create index if not exists idx_shipments_status on public.shipments(status);
create index if not exists idx_audit_store_created on public.audit_logs(store_id, created_at desc);
create index if not exists idx_notifications_user_read on public.notifications(user_id, is_read);

create or replace function public.touch_business_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;

drop trigger if exists stores_touch on public.stores;
create trigger stores_touch before update on public.stores for each row execute procedure public.touch_business_updated_at();
drop trigger if exists customers_touch on public.customers;
create trigger customers_touch before update on public.customers for each row execute procedure public.touch_business_updated_at();
drop trigger if exists shipments_touch on public.shipments;
create trigger shipments_touch before update on public.shipments for each row execute procedure public.touch_business_updated_at();

create or replace function public.current_store_id() returns uuid
language sql stable security definer set search_path=public as $$
  select store_id from public.profiles where id=auth.uid()
$$;

create or replace function public.is_management() returns boolean
language sql stable security definer set search_path=public as $$
  select coalesce(public.current_role() in ('admin','supervisor'), false)
$$;

alter table public.stores enable row level security;
alter table public.customers enable row level security;
alter table public.shipping_companies enable row level security;
alter table public.shipments enable row level security;
alter table public.audit_logs enable row level security;
alter table public.notifications enable row level security;
alter table public.system_settings enable row level security;

-- Remove old platform policies with these names so the migration can be re-run.
drop policy if exists "stores readable" on public.stores;
drop policy if exists "stores admin manage" on public.stores;
drop policy if exists "customers scoped read" on public.customers;
drop policy if exists "customers scoped write" on public.customers;
drop policy if exists "shipping companies read" on public.shipping_companies;
drop policy if exists "shipping companies admin manage" on public.shipping_companies;
drop policy if exists "shipments scoped read" on public.shipments;
drop policy if exists "shipments shipping manage" on public.shipments;
drop policy if exists "audit management read" on public.audit_logs;
drop policy if exists "notifications own" on public.notifications;
drop policy if exists "settings admin" on public.system_settings;

create policy "stores readable" on public.stores for select to authenticated using (
  public.is_management() or id=public.current_store_id() or owner_id=auth.uid()
);
create policy "stores admin manage" on public.stores for all to authenticated
using (public.current_role()='admin') with check (public.current_role()='admin');

create policy "customers scoped read" on public.customers for select to authenticated using (
  public.is_management() or store_id=public.current_store_id()
);
create policy "customers scoped write" on public.customers for all to authenticated using (
  public.is_management() or (public.current_role() in ('agent','store_owner') and store_id=public.current_store_id())
) with check (
  public.is_management() or (public.current_role() in ('agent','store_owner') and store_id=public.current_store_id())
);

create policy "shipping companies read" on public.shipping_companies for select to authenticated using (true);
create policy "shipping companies admin manage" on public.shipping_companies for all to authenticated
using (public.current_role()='admin') with check (public.current_role()='admin');

create policy "shipments scoped read" on public.shipments for select to authenticated using (
  public.current_role() in ('admin','supervisor','shipping','accountant') or exists (
    select 1 from public.orders o where o.id=order_id and (o.store_id=public.current_store_id() or o.assigned_to=auth.uid())
  )
);
create policy "shipments shipping manage" on public.shipments for all to authenticated using (
  public.current_role() in ('admin','supervisor','shipping')
) with check (public.current_role() in ('admin','supervisor','shipping'));

create policy "audit management read" on public.audit_logs for select to authenticated using (
  public.current_role() in ('admin','supervisor') or store_id=public.current_store_id()
);
create policy "notifications own" on public.notifications for all to authenticated
using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy "settings admin" on public.system_settings for all to authenticated
using (public.current_role()='admin') with check (public.current_role()='admin');

-- Platform-wide order policies that include store isolation.
drop policy if exists "orders select by role" on public.orders;
drop policy if exists "orders insert authenticated" on public.orders;
drop policy if exists "orders update by role" on public.orders;
drop policy if exists "orders delete admin" on public.orders;
create policy "orders select by role" on public.orders for select to authenticated using (
  public.current_role() in ('admin','supervisor','shipping','accountant')
  or assigned_to=auth.uid() or created_by=auth.uid() or store_id=public.current_store_id()
);
create policy "orders insert authenticated" on public.orders for insert to authenticated with check (
  public.current_role() in ('admin','supervisor') or store_id=public.current_store_id() or created_by=auth.uid()
);
create policy "orders update by role" on public.orders for update to authenticated using (
  public.current_role() in ('admin','supervisor','shipping') or assigned_to=auth.uid() or created_by=auth.uid()
) with check (
  public.current_role() in ('admin','supervisor','shipping') or assigned_to=auth.uid() or created_by=auth.uid()
);
create policy "orders delete admin" on public.orders for delete to authenticated using (public.current_role()='admin');
