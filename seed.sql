-- =====================================================================
-- seed.sql - Dữ liệu mẫu (chạy SAU schema.sql)
-- Mật khẩu mọi tài khoản: 123456 (băm bcrypt bằng pgcrypto, tương thích bcrypt Node.js)
-- Ngày dùng current_date để cảnh báo luôn có dữ liệu khi demo
-- =====================================================================

insert into users (email, password_hash, role, full_name) values
 ('admin@fleet.vn',  crypt('123456', gen_salt('bf', 10)), 'admin',  'Quản trị viên'),
 ('tai1@fleet.vn',   crypt('123456', gen_salt('bf', 10)), 'driver', 'Nguyễn Văn An'),
 ('tai2@fleet.vn',   crypt('123456', gen_salt('bf', 10)), 'driver', 'Trần Văn Bình'),
 ('tai3@fleet.vn',   crypt('123456', gen_salt('bf', 10)), 'driver', 'Lê Văn Cường');

insert into drivers (user_id, full_name, license_no, license_expiry, phone) values
 (2, 'Nguyễn Văn An',  'B2-001234', current_date + 400, '0901000001'),
 (3, 'Trần Văn Bình',  'C-002345',  current_date + 250, '0901000002'),
 (4, 'Lê Văn Cường',   'D-003456',  current_date + 600, '0901000003');

insert into vehicle_types (name, fuel_type) values
 ('Xe tải', 'diesel'), ('Xe con', 'xang'), ('Xe khách', 'diesel');

-- vehicles: current_odometer_km sẽ được trigger cập nhật theo phiếu đổ dầu
insert into vehicles (plate_number, vehicle_type_id, brand, model, year,
                      current_odometer_km, registration_expiry, insurance_expiry) values
 ('51C-123.45', 1, 'Hyundai', 'Porter',   2020, 50000, current_date + 12,  current_date + 200),  -- đăng kiểm sắp hết
 ('51A-678.90', 2, 'Toyota',  'Vios',     2021, 20000, current_date + 300, current_date + 20),   -- bảo hiểm sắp hết
 ('51B-246.80', 3, 'Thaco',   'Universe', 2019, 80000, current_date + 150, current_date + 150),
 ('51C-999.99', 1, 'Isuzu',   'QKR',      2022, 5000,  current_date - 3,   current_date + 90);   -- đăng kiểm đã quá hạn

insert into fuel_stations (name, address) values
 ('Petrolimex Cộng Hòa', '123 Cộng Hòa, Tân Bình, TP.HCM'),
 ('Petrolimex Quốc Lộ 1A', 'Km 1850, QL1A, Đồng Nai');

-- ---- Xe 1 (tải diesel ~25 L/100km): lần đổ thứ 4 cố tình hao bất thường
insert into fuel_tickets (vehicle_id, driver_id, station_id, filled_at, odometer_km, liters, unit_price, is_full_tank) values
 (1, 1, 1, now() - interval '40 days', 50000,  60, 20500, true),
 (1, 1, 1, now() - interval '30 days', 50400, 100, 20500, true),
 (1, 1, 2, now() - interval '20 days', 50800,  98, 20800, true),
 (1, 1, 2, now() - interval '10 days', 51200, 135, 21000, true),   -- 33.75 L/100km: bất thường
 (1, 1, 1, now() - interval '2 days',  51600, 101, 21000, true);

-- ---- Xe 2 (xe con ~8 L/100km)
insert into fuel_tickets (vehicle_id, driver_id, station_id, filled_at, odometer_km, liters, unit_price, is_full_tank) values
 (2, 2, 1, now() - interval '45 days', 20000, 35, 23000, true),
 (2, 2, 1, now() - interval '30 days', 20500, 40, 23200, true),
 (2, 2, 2, now() - interval '15 days', 21000, 41, 23500, true),
 (2, 2, 1, now() - interval '3 days',  21500, 39, 23500, true);

-- ---- Xe 3 (xe khách): có 1 lần đổ dở bình ở giữa để minh họa cộng dồn
insert into fuel_tickets (vehicle_id, driver_id, station_id, filled_at, odometer_km, liters, unit_price, is_full_tank) values
 (3, 3, 2, now() - interval '35 days', 80000,  90, 20500, true),
 (3, 3, 2, now() - interval '25 days', 80300,  30, 20600, false),  -- đổ dở, không làm mốc
 (3, 3, 1, now() - interval '12 days', 80700,  80, 20800, true),
 (3, 3, 1, now() - interval '4 days',  81200, 115, 21000, true);

insert into trips (vehicle_id, driver_id, origin, destination, assigned_at,
                   start_time, end_time, start_km, end_km, status) values
 (1, 1, 'TP.HCM', 'Cần Thơ',   now() - interval '12 days', now() - interval '11 days', now() - interval '11 days' + interval '8 hours', 50800, 51050, 'completed'),
 (2, 2, 'TP.HCM', 'Vũng Tàu',  now() - interval '5 days',  now() - interval '4 days',  now() - interval '4 days'  + interval '5 hours', 21000, 21250, 'completed'),
 (3, 3, 'TP.HCM', 'Đà Lạt',    now() - interval '2 days',  now() - interval '1 day',   null, 81200, null, 'in_progress'),
 (1, 1, 'TP.HCM', 'Biên Hòa',  now(), null, null, null, null, 'assigned');

insert into maintenance_types (name) values
 ('Thay dầu động cơ'), ('Đảo lốp / kiểm tra lốp'), ('Kiểm tra phanh');

-- Kế hoạch: chu kỳ km HOẶC tháng, cái nào tới trước thì lấy
insert into maintenance_plans (vehicle_id, maintenance_type_id, interval_km, interval_months,
                               start_odometer_km, start_date) values
 (1, 1, 10000, 6, 40000, current_date - 400),
 (2, 2, 10000, 6, 15000, current_date - 400),
 (3, 3, 20000, 12, 60000, current_date - 500),
 (4, 1, 10000, 6, 0, current_date - 30);        -- xe chưa bảo dưỡng lần nào: dùng mốc ban đầu

insert into maintenance_records (vehicle_id, maintenance_type_id, performed_at, odometer_km, cost, note) values
 -- Xe 1: đã đi 9.600 km / 10.000 km, mới ~5 tháng -> tới hạn theo KM trước
 (1, 1, current_date - 150, 42000, 1500000, 'Thay dầu + lọc dầu'),
 -- Xe 2: chỉ đi 3.000 km nhưng đã 7 tháng -> tới hạn theo THỜI GIAN trước
 (2, 2, current_date - 210, 18500, 400000, 'Đảo lốp'),
 -- Xe 3: còn xa mốc
 (3, 3, current_date - 100, 78000, 2200000, 'Thay má phanh');

insert into incidents (vehicle_id, driver_id, trip_id, description, lat, lng, image_url, status) values
 (1, 1, 1, 'Nổ lốp trên đường đi Cần Thơ', 10.512345, 106.345678, 'https://example.com/incident1.jpg', 'resolved'),
 (3, 3, 3, 'Xe chết máy tại đèo Prenn',    11.879000, 108.470000, 'https://example.com/incident2.jpg', 'open');
