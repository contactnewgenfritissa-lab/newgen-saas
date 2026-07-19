-- شغّل هذا الملف مرة واحدة داخل Supabase SQL Editor
create extension if not exists pgcrypto;

create type public.user_role as enum ('admin','supervisor','agent','shipping','store_owner','accountant');
create type public.order_status as enum ('new','pending_call','no_answer','callback','confirmed','modified','cancelled','wrong_number','ready_to_ship','shipped','out_for_delivery','delivered','returned','refused');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  role public.user_role not null default 'agent',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  phone text not null,
  city text not null,
  address text,
  product_name text not null,
  quantity integer not null default 1 check (quantity > 0),
  price numeric(12,2) not null default 0,
  shipping_fee numeric(12,2) not null default 0,
  total_amount numeric(12,2) generated always as ((quantity * price) + shipping_fee) stored,
  status public.order_status not null default 'new',
  assigned_to uuid references public.profiles(id) on delete set null,
  callback_at timestamptz,
  notes text,
  created_by uuid references public.profiles(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.order_status_history (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders(id) on delete cascade,
  old_status public.order_status,
  new_status public.order_status not null,
  changed_by uuid references public.profiles(id) on delete set null default auth.uid(),
  changed_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,full_name,email)
  values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),new.email);
  return new;
end;$$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$begin new.updated_at=now(); return new; end;$$;
create trigger orders_touch before update on public.orders for each row execute procedure public.touch_updated_at();

create or replace function public.log_status_change()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if old.status is distinct from new.status then
    insert into public.order_status_history(order_id,old_status,new_status,changed_by)
    values(new.id,old.status,new.status,auth.uid());
  end if;
  return new;
end;$$;
create trigger orders_status_audit after update on public.orders for each row execute procedure public.log_status_change();

alter table public.profiles enable row level security;
alter table public.orders enable row level security;
alter table public.order_status_history enable row level security;

create or replace function public.current_role() returns public.user_role language sql stable security definer set search_path=public as $$select role from public.profiles where id=auth.uid()$$;

create policy "profiles read authenticated" on public.profiles for select to authenticated using (true);
create policy "profiles admin update" on public.profiles for update to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');

create policy "orders select by role" on public.orders for select to authenticated using (
  public.current_role() in ('admin','supervisor','shipping','accountant') or assigned_to=auth.uid() or created_by=auth.uid()
);
create policy "orders insert authenticated" on public.orders for insert to authenticated with check (auth.uid() is not null);
create policy "orders update by role" on public.orders for update to authenticated using (
  public.current_role() in ('admin','supervisor','shipping') or assigned_to=auth.uid() or created_by=auth.uid()
) with check (
  public.current_role() in ('admin','supervisor','shipping') or assigned_to=auth.uid() or created_by=auth.uid()
);
create policy "orders delete admin" on public.orders for delete to authenticated using (public.current_role()='admin');

create policy "history read" on public.order_status_history for select to authenticated using (true);

-- بعد إنشاء أول حساب، استبدل البريد ثم شغّل السطر التالي:
-- update public.profiles set role='admin' where email='your@email.com';
