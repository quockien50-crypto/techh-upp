package vn.edu.vhu.ltdd.detai1;

import java.util.ArrayList;

public class FuelActivity extends SimpleListActivity {
    @Override protected String getScreenTitle() { return "Theo dõi nhiên liệu"; }
    @Override protected String[] getFieldNames() { return new String[] {"Mã phiếu", "Biển số xe", "Ngày đổ (dd/MM/yyyy)", "Số lít", "Đơn giá/lít (VNĐ)"}; }
    @Override protected ArrayList<DataStore.Record> getRecords() { return DataStore.fuels; }
    @Override protected String getAddButtonText() { return "THÊM LẦN ĐỔ NHIÊN LIỆU"; }
}
