package vn.edu.vhu.ltdd.detai1;

import java.util.ArrayList;

public class MaintenanceActivity extends SimpleListActivity {
    @Override protected String getScreenTitle() { return "Quản lý bảo dưỡng"; }
    @Override protected String[] getFieldNames() { return new String[] {"Mã phiếu", "Biển số xe", "Ngày bảo dưỡng (dd/MM/yyyy)", "Nội dung", "Chi phí (VNĐ)", "Trạng thái"}; }
    @Override protected ArrayList<DataStore.Record> getRecords() { return DataStore.maintenances; }
    @Override protected String getAddButtonText() { return "LẬP LỊCH BẢO DƯỠNG"; }
}
