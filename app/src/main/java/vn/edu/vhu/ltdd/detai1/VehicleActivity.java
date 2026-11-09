package vn.edu.vhu.ltdd.detai1;

import java.util.ArrayList;

public class VehicleActivity extends SimpleListActivity {
    @Override protected String getScreenTitle() { return "Quản lý đội xe"; }
    @Override protected String[] getFieldNames() { return new String[] {"Mã xe", "Biển số", "Hãng xe", "Loại xe", "Hạn đăng kiểm (dd/MM/yyyy)", "Hạn bảo hiểm (dd/MM/yyyy)"}; }
    @Override protected ArrayList<DataStore.Record> getRecords() { return DataStore.vehicles; }
    @Override protected String getAddButtonText() { return "THÊM XE"; }
}
