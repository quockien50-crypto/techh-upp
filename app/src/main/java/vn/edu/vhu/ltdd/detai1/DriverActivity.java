package vn.edu.vhu.ltdd.detai1;

import java.util.ArrayList;

public class DriverActivity extends SimpleListActivity {
    @Override protected String getScreenTitle() { return "Quản lý tài xế"; }
    @Override protected String[] getFieldNames() { return new String[] {"Mã tài xế", "Họ tên", "Số điện thoại", "Hạng bằng lái"}; }
    @Override protected ArrayList<DataStore.Record> getRecords() { return DataStore.drivers; }
    @Override protected String getAddButtonText() { return "THÊM TÀI XẾ"; }
}
