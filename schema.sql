-- =====================================================================
-- schema.sql - Quản lý đội xe (PostgreSQL / Supabase)
-- Chạy trong Supabase: Dashboard -> SQL Editor -> dán -> Run
-- Thứ tự chạy: schema.sql -> seed.sql
-- =====================================================================

create extension if not exists pgcrypto;   -- dùng cho seed (crypt/bcrypt)

-- Xóa theo thứ tự ngược để chạy lại được nhiều lần
drop view  if exists v_monthly_costs, v_expiry_alerts, v_maintenance_due,
                     v_fuel_alerts, v_fuel_consumption cascade;
drop table if exists incidents, maintenance_records, maintenance_plans,
                     maintenance_types, fuel_tickets, fuel_stations, trips,
                     vehicles, vehicle_types, drivers, users cascade;

-- 1. Tài khoản (Sang dùng cho JWT + bcrypt, phân quyền theo role)
create table users (
  id            serial primary key,
  email         text unique not null,
  password_hash text not null,
  role          text not null check (role in ('admin', 'driver')),
  full_name     text not null,
  created_at    timestamptz not null default now()
);

-- 2. Tài xế (1-1 với users có role = driver)
create table drivers (
  id             serial primary key,
  user_id        int unique references users(id) on delete set null,
  full_name      text not null,
  license_no     text unique,
  license_expiry date,
  phone          text
);

-- 3. Loại xe
create table vehicle_types (
  id        serial primary key,
  name      text not null,
  fuel_type text not null check (fuel_type in ('diesel', 'xang'))
);

-- 4. Xe (có hạn đăng kiểm / bảo hiểm cho cảnh báo trước 30 ngày)
create table vehicles (
  id                  serial primary key,
  plate_number        text unique not null,
  vehicle_type_id     int not null references vehicle_types(id),
  brand               text,
  model               text,
  year                int,
  current_odometer_km numeric(10,1) not null default 0,
  registration_expiry date,        -- hạn đăng kiểm
  insurance_expiry    date,        -- hạn bảo hiểm
  status              text not null default 'active'
                      check (status in ('active', 'maintenance', 'inactive'))
);

-- 5. Chuyến đi (Duy ghi km đầu / km cuối)
create table trips (
  id          serial primary key,
  vehicle_id  int not null references vehicles(id),
  driver_id   int not null references drivers(id),
  origin      text,
  destination text,
  assigned_at timestamptz not null default now(),
  start_time  timestamptz,
  end_time    timestamptz,
  start_km    numeric(10,1),
  end_km      numeric(10,1),
  status      text not null default 'assigned'
              check (status in ('assigned', 'in_progress', 'completed', 'cancelled')),
  check (end_km is null or start_km is null or end_km >= start_km)
);

-- 6. Trạm xăng
create table fuel_stations (
  id      serial primary key,
  name    text not null,
  address text
);

-- 7. Phiếu đổ nhiên liệu (có ảnh hóa đơn)
create table fuel_tickets (
  id          serial primary key,
  vehicle_id  int not null references vehicles(id),
  driver_id   int references drivers(id),
  trip_id     int references trips(id),
  station_id  int references fuel_stations(id),
  filled_at   timestamptz not null,
  odometer_km numeric(10,1) not null,
  liters      numeric(7,2) not null check (liters > 0),
  unit_price  numeric(10,0) not null default 0,
  total_cost  numeric(14,0) generated always as (round(liters * unit_price)) stored,
  is_full_tank boolean not null default true,
  receipt_url text
);
create index idx_fuel_vehicle_time on fuel_tickets (vehicle_id, filled_at);

-- 8. Loại bảo dưỡng
create table maintenance_types (
  id   serial primary key,
  name text not null
);

-- 9. Kế hoạch bảo dưỡng định kỳ theo từng xe (theo km HOẶC thời gian)
create table maintenance_plans (
  id                 serial primary key,
  vehicle_id         int not null references vehicles(id) on delete cascade,
  maintenance_type_id int not null references maintenance_types(id),
  interval_km        int not null check (interval_km > 0),
  interval_months    int not null check (interval_months > 0),
  start_odometer_km  numeric(10,1) not null default 0,  -- mốc ban đầu nếu chưa bảo dưỡng lần nào
  start_date         date not null default current_date,
  is_active          boolean not null default true,
  unique (vehicle_id, maintenance_type_id)
);

-- 10. Lịch sử bảo dưỡng
create table maintenance_records (
  id                  serial primary key,
  vehicle_id          int not null references vehicles(id),
  maintenance_type_id int not null references maintenance_types(id),
  performed_at        date not null,
  odometer_km         numeric(10,1) not null,
  cost                numeric(12,0) not null default 0,
  note                text
);

-- 11. Báo cáo sự cố (kèm tọa độ + ảnh)
create table incidents (
  id          serial primary key,
  vehicle_id  int not null references vehicles(id),
  driver_id   int not null references drivers(id),
  trip_id     int references trips(id),
  description text not null,
  lat         numeric(9,6) check (lat between -90 and 90),
  lng         numeric(9,6) check (lng between -180 and 180),
  image_url   text,
  status      text not null default 'open' check (status in ('open', 'resolved')),
  reported_at timestamptz not null default now()
);

-- =====================================================================
-- TRIGGER: chặn nhập lùi số km + tự cập nhật km hiện tại của xe
-- =====================================================================
create or replace function trg_check_fuel_odometer() returns trigger as $$
begin
  if exists (select 1 from fuel_tickets t
             where t.vehicle_id = new.vehicle_id
               and t.id is distinct from new.id
               and ((t.filled_at <= new.filled_at and t.odometer_km > new.odometer_km)
                 or (t.filled_at >  new.filled_at and t.odometer_km < new.odometer_km))) then
    raise exception 'Số km % không hợp lệ: phải tăng dần theo thời gian đổ dầu', new.odometer_km;
  end if;
  return new;
end $$ language plpgsql;

create trigger fuel_odometer_check
  before insert or update on fuel_tickets
  for each row execute function trg_check_fuel_odometer();

create or replace function trg_update_vehicle_odometer() returns trigger as $$
begin
  update vehicles
     set current_odometer_km = greatest(current_odometer_km, new.odometer_km)
   where id = new.vehicle_id;
  return new;
end $$ language plpgsql;

create trigger fuel_update_odometer
  after insert or update on fuel_tickets
  for each row execute function trg_update_vehicle_odometer();

-- =====================================================================
-- VIEW 1 (ĐIỂM NHẤN): tiêu hao nhiên liệu lít/100km bằng LAG
-- Chỉ lấy các lần đổ đầy bình làm mốc. Nếu giữa 2 mốc có lần đổ dở
-- (is_full_tank = false) thì cộng dồn lượng dầu đó vào.
-- =====================================================================
create or replace view v_fuel_consumption as
with full_fills as (
  select
    ft.id, ft.vehicle_id, ft.filled_at, ft.odometer_km,
    lag(ft.odometer_km) over w as prev_odometer_km,
    lag(ft.filled_at)   over w as prev_filled_at
  from fuel_tickets ft
  where ft.is_full_tank
  window w as (partition by ft.vehicle_id order by ft.filled_at, ft.id)
)
select
  f.id as fuel_ticket_id,
  f.vehicle_id,
  v.plate_number,
  f.prev_filled_at,
  f.filled_at,
  f.odometer_km - f.prev_odometer_km as km_driven,
  s.liters_used,
  round(s.liters_used / nullif(f.odometer_km - f.prev_odometer_km, 0) * 100, 2) as l_per_100km
from full_fills f
join vehicles v on v.id = f.vehicle_id
cross join lateral (
  select sum(t.liters) as liters_used
  from fuel_tickets t
  where t.vehicle_id = f.vehicle_id
    and t.filled_at >  f.prev_filled_at
    and t.filled_at <= f.filled_at
) s
where f.prev_odometer_km is not null;

-- VIEW 2: cảnh báo hao dầu bất thường (> 120% mức trung bình của chính xe đó)
create or replace view v_fuel_alerts as
select
  plate_number, filled_at, km_driven, liters_used, l_per_100km,
  round(avg(l_per_100km) over (partition by vehicle_id), 2) as avg_l_per_100km,
  l_per_100km > 1.2 * avg(l_per_100km) over (partition by vehicle_id) as is_abnormal
from v_fuel_consumption;

-- =====================================================================
-- VIEW 3: mốc bảo dưỡng ưu tiên - điều kiện nào TỚI TRƯỚC thì lấy
--   progress_km   = % quãng đường đã đi so với chu kỳ km
--   progress_time = % thời gian đã qua so với chu kỳ tháng
--   Điều kiện có % cao hơn là điều kiện tới trước -> due_by
-- =====================================================================
create or replace view v_maintenance_due as
with base as (
  select
    p.id as plan_id, p.vehicle_id, v.plate_number,
    mt.name as maintenance_name,
    p.interval_km, p.interval_months, v.current_odometer_km,
    coalesce(lr.odometer_km, p.start_odometer_km) as last_km,
    coalesce(lr.performed_at, p.start_date)       as last_date
  from maintenance_plans p
  join vehicles v            on v.id  = p.vehicle_id
  join maintenance_types mt  on mt.id = p.maintenance_type_id
  left join lateral (
    select r.odometer_km, r.performed_at
    from maintenance_records r
    where r.vehicle_id = p.vehicle_id
      and r.maintenance_type_id = p.maintenance_type_id
    order by r.performed_at desc, r.id desc
    limit 1
  ) lr on true
  where p.is_active
),
calc as (
  select *,
    last_km + interval_km as due_km,
    (last_date + make_interval(months => interval_months))::date as due_date
  from base
),
prog as (
  select *,
    due_km - current_odometer_km as km_remaining,
    due_date - current_date      as days_remaining,
    (current_odometer_km - last_km) / interval_km as progress_km,
    (current_date - last_date)::numeric / nullif(due_date - last_date, 0) as progress_time
  from calc
)
select
  plan_id, vehicle_id, plate_number, maintenance_name,
  last_km, last_date, due_km, due_date, km_remaining, days_remaining,
  round(greatest(progress_km, progress_time) * 100, 1) as progress_pct,
  case when progress_km >= progress_time then 'km' else 'time' end as due_by,
  case
    when km_remaining <= 0 or days_remaining <= 0 then 'overdue'
    when km_remaining <= 1000 or days_remaining <= 30 then 'due_soon'
    else 'ok'
  end as status
from prog
order by progress_pct desc;

-- VIEW 4: xe sắp / đã hết hạn đăng kiểm hoặc bảo hiểm (trong 30 ngày)
create or replace view v_expiry_alerts as
select v.id as vehicle_id, v.plate_number, 'Đăng kiểm' as doc_type,
       v.registration_expiry as expiry_date,
       v.registration_expiry - current_date as days_left
from vehicles v
where v.registration_expiry <= current_date + 30
union all
select v.id, v.plate_number, 'Bảo hiểm',
       v.insurance_expiry, v.insurance_expiry - current_date
from vehicles v
where v.insurance_expiry <= current_date + 30
order by days_left;

-- VIEW 5: chi phí theo tháng và theo xe (cho biểu đồ báo cáo của Quốc)
create or replace view v_monthly_costs as
select vehicle_id, month, sum(fuel_cost) as fuel_cost, sum(maint_cost) as maint_cost,
       sum(fuel_cost) + sum(maint_cost) as total_cost
from (
  select vehicle_id, date_trunc('month', filled_at)::date as month,
         total_cost as fuel_cost, 0::numeric as maint_cost
  from fuel_tickets
  union all
  select vehicle_id, date_trunc('month', performed_at)::date,
         0, cost
  from maintenance_records
) x
group by vehicle_id, month;
