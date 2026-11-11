-- =====================================================================
-- queries.sql - Các truy vấn demo / bảo vệ đồ án
-- =====================================================================

-- 1. ĐIỂM NHẤN: tiêu hao nhiên liệu lít/100km giữa 2 lần đổ đầy liên tiếp (LAG)
select plate_number, prev_filled_at::date, filled_at::date, km_driven, liters_used, l_per_100km
from v_fuel_consumption
order by plate_number, filled_at;

-- 2. Cảnh báo hao dầu bất thường
select * from v_fuel_alerts where is_abnormal;

-- 3. Mốc bảo dưỡng ưu tiên (km hoặc thời gian, cái nào tới trước)
select plate_number, maintenance_name, due_km, due_date, km_remaining, days_remaining,
       progress_pct, due_by, status
from v_maintenance_due;

-- 4. Xe sắp/đã hết hạn đăng kiểm, bảo hiểm trong 30 ngày
select * from v_expiry_alerts;

-- 5. Chi phí theo tháng (cho biểu đồ)
select to_char(month, 'YYYY-MM') as thang, sum(fuel_cost) as nhien_lieu,
       sum(maint_cost) as bao_duong, sum(total_cost) as tong
from v_monthly_costs
group by month order by month;

-- 6. Kiểm tra trigger chặn nhập lùi km (kỳ vọng: báo lỗi)
-- insert into fuel_tickets (vehicle_id, filled_at, odometer_km, liters, unit_price)
-- values (1, now(), 10, 50, 21000);
