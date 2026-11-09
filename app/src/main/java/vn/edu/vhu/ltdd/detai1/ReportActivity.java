package vn.edu.vhu.ltdd.detai1;

import android.os.Bundle;
import android.widget.TextView;
import android.widget.Button;
import androidx.appcompat.app.AppCompatActivity;

public class ReportActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        DataStore.init();
        setContentView(R.layout.activity_report);

        TextView tvVehicles = findViewById(R.id.tvReportVehicles);
        TextView tvFuel = findViewById(R.id.tvReportFuel);
        TextView tvMaintenance = findViewById(R.id.tvReportMaintenance);
        TextView tvTotal = findViewById(R.id.tvReportTotal);
        Button back = findViewById(R.id.btnBackReport);
        CostChartView chart = findViewById(R.id.costChart);

        double fuelCost = 0;
        for (DataStore.Record r : DataStore.fuels) {
            try {
                double liters = Double.parseDouble(r.values[3]);
                double unitPrice = Double.parseDouble(r.values[4]);
                fuelCost += liters * unitPrice;
            } catch (NumberFormatException ignored) {}
        }

        double maintenanceCost = 0;
        for (DataStore.Record r : DataStore.maintenances) {
            try {
                maintenanceCost += Double.parseDouble(r.values[4]);
            } catch (NumberFormatException ignored) {}
        }

        double total = fuelCost + maintenanceCost;
        tvVehicles.setText("Tổng số xe: " + DataStore.vehicles.size());
        tvFuel.setText("Chi phí nhiên liệu: " + formatMoney(fuelCost) + " VNĐ");
        tvMaintenance.setText("Chi phí bảo dưỡng: " + formatMoney(maintenanceCost) + " VNĐ");
        tvTotal.setText("TỔNG CHI PHÍ: " + formatMoney(total) + " VNĐ");
        chart.setCosts(fuelCost, maintenanceCost);

        back.setOnClickListener(v -> finish());
    }

    private String formatMoney(double value) {
        return String.format("%,.0f", value);
    }
}
