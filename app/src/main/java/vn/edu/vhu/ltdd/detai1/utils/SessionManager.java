
package vn.edu.vhu.ltdd.detai1.utils;

import android.content.Context;
import android.content.SharedPreferences;

public class SessionManager {

    private static final String PREF_NAME = "ADMIN_SESSION";
    private static final String KEY_TOKEN = "token";
    private static final String KEY_ROLE = "role";
    private static final String KEY_EXPIRE = "expire";

    private SharedPreferences preferences;

    public SessionManager(Context context) {
        preferences = context.getSharedPreferences(
                PREF_NAME, Context.MODE_PRIVATE);
    }

    public void saveSession(String token, String role,
                            long expireTime) {

        preferences.edit()
                .putString(KEY_TOKEN, token)
                .putString(KEY_ROLE, role)
                .putLong(KEY_EXPIRE, expireTime)
                .apply();
    }

    public String getToken() {
        return preferences.getString(KEY_TOKEN, "");
    }

    public String getRole() {
        return preferences.getString(KEY_ROLE, "");
    }

    public boolean isLoggedIn() {
        String token = getToken();
        long expire = preferences.getLong(KEY_EXPIRE, 0);

        return !token.isEmpty()
                && System.currentTimeMillis() < expire;
    }

    public void logout() {
        preferences.edit().clear().apply();
    }
}
