package vn.edu.vhu.ltdd.detai1;

import java.util.ArrayList;

public class DataStore {
    public static class Record {
        public String[] values;
        public Record(String... values) { this.values = values; }
    }

    public static final ArrayList<Record> vehicles = new ArrayList<>();
    public static final ArrayList<Record> drivers = new ArrayList<>();
    public static final ArrayList<Record> maintenances = new ArrayList<>();
    public static final ArrayList<Record> fuels = new ArrayList<>();

    private static boolean initialized = false;

    public static void init() {
        if (initialized) return;
        initialized = true;
        vehicles.add(new Record("XE001", "51A-12345", "Hyundai", "Xe tải",
                "20/12/2026", "20/01/2027"));
        drivers.add(new Record("TX001", "Nguyễn Văn An", "0901234567", "B2"));
        maintenances.add(new Record("BD001", "51A-12345", "15/11/2026",
                "Thay dầu và kiểm tra phanh", "1500000", "Đã lên lịch"));
        fuels.add(new Record("NL001", "51A-12345", "08/11/2026",
                "60", "25000"));
    }
}
