
package vn.edu.vhu.ltdd.detai1;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import vn.edu.vhu.ltdd.detai1.utils.SessionManager;

public class LoginActivity extends AppCompatActivity {

    private EditText edtUsername, edtPassword;
    private Button btnLogin;
    private TextView tvError;

    private SessionManager sessionManager;

    private static final String TAG = "NHOMTECHUP_LOGIN";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        sessionManager = new SessionManager(this);

        if (sessionManager.isLoggedIn()) {
            openMain();
            return;
        }

        setContentView(R.layout.activity_login);

        edtUsername = findViewById(R.id.edtUsername);
        edtPassword = findViewById(R.id.edtPassword);
        btnLogin = findViewById(R.id.btnLogin);
        tvError = findViewById(R.id.tvError);

        btnLogin.setOnClickListener(v -> login());
    }

    private void login() {

        String username = edtUsername.getText()
                .toString().trim();

        String password = edtPassword.getText()
                .toString().trim();

        edtUsername.setError(null);
        edtPassword.setError(null);
        tvError.setText("");

        if (username.isEmpty()) {
            edtUsername.setError("Vui lòng nhập tài khoản");
            edtUsername.requestFocus();
            return;
        }

        if (password.isEmpty()) {
            edtPassword.setError("Vui lòng nhập mật khẩu");
            edtPassword.requestFocus();
            return;
        }

        String role = "";

        if (username.equals("admin")
                && password.equals("123456")) {

            role = "ADMIN";

        } else if (username.equals("nhanvien")
                && password.equals("123456")) {

            role = "EMPLOYEE";
        }

        if (role.isEmpty()) {

            tvError.setText("Tài khoản hoặc mật khẩu không đúng");

            return;
        }

        // Token demo, thay bằng token từ Backend khi tích hợp API.
        String demoToken = "DEMO_" + username + "_TOKEN";

        // Token demo có thời hạn 8 tiếng.
        long expireTime = System.currentTimeMillis()
                + (8 * 60 * 60 * 1000L);

        sessionManager.saveSession(
                demoToken, role, expireTime);

        android.util.Log.d(TAG, "Login successful: " + role);

        Toast.makeText(this,
                "Đăng nhập thành công",
                Toast.LENGTH_SHORT).show();

        openMain();
    }

    private void openMain() {

        Intent intent = new Intent(
                LoginActivity.this, MainActivity.class);

        startActivity(intent);
        finish();
    }
}
