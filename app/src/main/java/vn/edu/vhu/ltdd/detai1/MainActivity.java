
package vn.edu.vhu.ltdd.detai1;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import vn.edu.vhu.ltdd.detai1.utils.SessionManager;

public class MainActivity extends AppCompatActivity {

    private SessionManager sessionManager;

    private Button btnVehicle;
    private Button btnDriver;
    private Button btnMaintenance;
    private Button btnFuel;
    private Button btnAlert;
    private Button btnReport;
    private Button btnLogout;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        sessionManager = new SessionManager(this);

        if (!sessionManager.isLoggedIn()) {
            goToLogin();
            return;
        }

        setContentView(R.layout.activity_main);

        TextView tvWelcome = findViewById(R.id.tvWelcome);

        btnVehicle = findViewById(R.id.btnVehicle);
        btnDriver = findViewById(R.id.btnDriver);
        btnMaintenance = findViewById(R.id.btnMaintenance);
        btnFuel = findViewById(R.id.btnFuel);
        btnAlert = findViewById(R.id.btnAlert);
        btnReport = findViewById(R.id.btnReport);
        btnLogout = findViewById(R.id.btnLogout);

        String role = sessionManager.getRole();

        if ("ADMIN".equals(role)) {
            tvWelcome.setText("XIN CHÀO ADMIN");
        } else {
            tvWelcome.setText("XIN CHÀO NHÂN VIÊN");

            // Phân quyền nhân viên
            btnDriver.setVisibility(android.view.View.GONE);
            btnReport.setVisibility(android.view.View.GONE);
        }

        btnVehicle.setOnClickListener(v ->
                openScreen(VehicleActivity.class));

        btnDriver.setOnClickListener(v ->
                openScreen(DriverActivity.class));

        btnMaintenance.setOnClickListener(v ->
                openScreen(MaintenanceActivity.class));

        btnFuel.setOnClickListener(v ->
                openScreen(FuelActivity.class));

        btnAlert.setOnClickListener(v ->
                openScreen(AlertActivity.class));

        btnReport.setOnClickListener(v ->
                openScreen(ReportActivity.class));

        btnLogout.setOnClickListener(v -> logout());
    }

    private void openScreen(Class<?> screen) {
        startActivity(new Intent(this, screen));
    }

    private void logout() {
        sessionManager.logout();
        Toast.makeText(this,
                "Đã đăng xuất",
                Toast.LENGTH_SHORT).show();
        goToLogin();
    }

    private void goToLogin() {
        Intent intent = new Intent(
                MainActivity.this, LoginActivity.class);

        intent.setFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK |
                        Intent.FLAG_ACTIVITY_CLEAR_TASK);

        startActivity(intent);
        finish();
    }

    @Override
    protected void onResume() {
        super.onResume();

        if (sessionManager != null
                && !sessionManager.isLoggedIn()) {
            goToLogin();
        }
    }
}
