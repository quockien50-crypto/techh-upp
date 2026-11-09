package vn.edu.vhu.ltdd.detai1;

import android.os.Bundle;
import android.widget.TextView;
import android.widget.Button;
import android.widget.LinearLayout;
import androidx.appcompat.app.AppCompatActivity;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.concurrent.TimeUnit;

public class AlertActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        DataStore.init();
        setContentView(R.layout.activity_alert);

        LinearLayout container = findViewById(R.id.alertContainer);
        Button back = findViewById(R.id.btnBackAlert);
        back.setOnClickListener(v -> finish());

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy", Locale.getDefault());
        long today = System.currentTimeMillis();
        int count = 0;

        for (DataStore.Record vehicle : DataStore.vehicles) {
            String plate = vehicle.values[1];
            count += addAlertIfNeeded(container, plate, "Đăng kiểm", vehicle.values[4], sdf, today);
            count += addAlertIfNeeded(container, plate, "Bảo hiểm", vehicle.values[5], sdf, today);
        }

        if (count == 0) {
            TextView empty = new TextView(this);
            empty.setText("Hiện không có xe nào sắp hết hạn trong 30 ngày.");
            empty.setTextSize(16);
            empty.setPadding(12, 24, 12, 24);
            container.addView(empty);
        }
    }

    private int addAlertIfNeeded(LinearLayout container, String plate, String type,
                                 String dateText, SimpleDateFormat sdf, long today) {
        try {
            Date expiry = sdf.parse(dateText);
            if (expiry == null) return 0;
            long days = TimeUnit.MILLISECONDS.toDays(expiry.getTime() - today);
            if (days >= 0 && days <= 30) {
                TextView item = new TextView(this);
                item.setText(plate + " - " + type + " hết hạn ngày " + dateText
                        + " (còn " + days + " ngày)");
                item.setTextSize(16);
                item.setPadding(12, 16, 12, 16);
                container.addView(item);
                return 1;
            }
        } catch (Exception ignored) {
            // Ngay khong dung dinh dang dd/MM/yyyy se duoc bo qua.
        }
        return 0;
    }
}
