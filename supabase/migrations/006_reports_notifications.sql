-- Reporting views and helper functions.
create or replace view public.daily_order_metrics as
select
  date_trunc('day', created_at)::date as metric_date,
  store_id,
  count(*) as total_orders,
  count(*) filter (where status='confirmed') as confirmed_orders,
  count(*) filter (where status='delivered') as delivered_orders,
  count(*) filter (where status in ('returned','refused')) as failed_orders,
  coalesce(sum(total_amount) filter (where status='delivered'),0) as delivered_revenue
from public.orders
group by 1,2;

grant select on public.daily_order_metrics to authenticated;

create or replace function public.dashboard_kpis()
returns jsonb language sql stable security invoker as $$
  select jsonb_build_object(
    'total_orders', count(*),
    'confirmed', count(*) filter (where status='confirmed'),
    'delivered', count(*) filter (where status='delivered'),
    'callbacks', count(*) filter (where status='callback'),
    'revenue', coalesce(sum(total_amount) filter (where status='delivered'),0)
  ) from public.orders
$$;
grant execute on function public.dashboard_kpis() to authenticated;
