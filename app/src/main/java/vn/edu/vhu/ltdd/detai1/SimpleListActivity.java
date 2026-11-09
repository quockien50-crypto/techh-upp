package vn.edu.vhu.ltdd.detai1;

import android.app.AlertDialog;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import java.util.ArrayList;

public abstract class SimpleListActivity extends AppCompatActivity {
    protected abstract String getScreenTitle();
    protected abstract String[] getFieldNames();
    protected abstract ArrayList<DataStore.Record> getRecords();
    protected abstract String getAddButtonText();

    private final ArrayList<EditText> inputs = new ArrayList<>();
    private final ArrayList<String> visibleItems = new ArrayList<>();
    private ArrayAdapter<String> adapter;
    private EditText edtSearch;
    private ListView listView;
    private Button btnAdd;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        DataStore.init();
        setContentView(R.layout.activity_simple_list);

        TextView tvTitle = findViewById(R.id.tvScreenTitle);
        LinearLayout formContainer = findViewById(R.id.formContainer);
        edtSearch = findViewById(R.id.edtSearch);
        btnAdd = findViewById(R.id.btnAdd);
        Button btnBack = findViewById(R.id.btnBack);
        listView = findViewById(R.id.listViewRecords);

        tvTitle.setText(getScreenTitle());
        btnAdd.setText(getAddButtonText());

        for (String field : getFieldNames()) {
            EditText editText = new EditText(this);
            editText.setSingleLine(true);
            editText.setHint(field);
            formContainer.addView(editText);
            inputs.add(editText);
        }

        adapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, visibleItems);
        listView.setAdapter(adapter);
        refreshList("");

        btnAdd.setOnClickListener(v -> addRecord());
        btnBack.setOnClickListener(v -> finish());

        edtSearch.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {
                refreshList(s.toString());
            }
            @Override public void afterTextChanged(Editable s) {}
        });

        listView.setOnItemClickListener((parent, view, position, id) -> {
            String query = edtSearch.getText().toString().toLowerCase();
            ArrayList<DataStore.Record> filtered = getFilteredRecords(query);
            if (position < filtered.size()) editRecord(filtered.get(position));
        });

        listView.setOnItemLongClickListener((parent, view, position, id) -> {
            String query = edtSearch.getText().toString().toLowerCase();
            ArrayList<DataStore.Record> filtered = getFilteredRecords(query);
            if (position < filtered.size()) deleteRecord(filtered.get(position));
            return true;
        });
    }

    private void addRecord() {
        String[] values = new String[inputs.size()];
        for (int i = 0; i < inputs.size(); i++) {
            values[i] = inputs.get(i).getText().toString().trim();
            if (values[i].isEmpty()) {
                inputs.get(i).setError("Vui lòng nhập thông tin");
                inputs.get(i).requestFocus();
                return;
            }
        }
        getRecords().add(new DataStore.Record(values));
        clearInputs();
        refreshList(edtSearch.getText().toString());
        Toast.makeText(this, "Đã thêm dữ liệu", Toast.LENGTH_SHORT).show();
    }

    private void editRecord(DataStore.Record record) {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(24, 8, 24, 0);
        EditText[] editTexts = new EditText[record.values.length];

        String[] names = getFieldNames();
        for (int i = 0; i < record.values.length; i++) {
            EditText e = new EditText(this);
            e.setSingleLine(true);
            e.setHint(names[i]);
            e.setText(record.values[i]);
            box.addView(e);
            editTexts[i] = e;
        }

        new AlertDialog.Builder(this)
                .setTitle("Sửa thông tin")
                .setView(box)
                .setPositiveButton("Lưu", (dialog, which) -> {
                    for (int i = 0; i < editTexts.length; i++) {
                        String value = editTexts[i].getText().toString().trim();
                        if (value.isEmpty()) {
                            Toast.makeText(this, "Thông tin không được để trống", Toast.LENGTH_SHORT).show();
                            return;
                        }
                        record.values[i] = value;
                    }
                    refreshList(edtSearch.getText().toString());
                    Toast.makeText(this, "Đã cập nhật", Toast.LENGTH_SHORT).show();
                })
                .setNegativeButton("Hủy", null)
                .show();
    }

    private void deleteRecord(DataStore.Record record) {
        new AlertDialog.Builder(this)
                .setTitle("Xóa dữ liệu")
                .setMessage("Bạn có chắc muốn xóa mục này?")
                .setPositiveButton("Xóa", (dialog, which) -> {
                    getRecords().remove(record);
                    refreshList(edtSearch.getText().toString());
                    Toast.makeText(this, "Đã xóa", Toast.LENGTH_SHORT).show();
                })
                .setNegativeButton("Hủy", null)
                .show();
    }

    private ArrayList<DataStore.Record> getFilteredRecords(String query) {
        ArrayList<DataStore.Record> result = new ArrayList<>();
        for (DataStore.Record r : getRecords()) {
            StringBuilder text = new StringBuilder();
            for (String value : r.values) text.append(value).append(" ");
            if (text.toString().toLowerCase().contains(query)) result.add(r);
        }
        return result;
    }

    private void refreshList(String queryText) {
        visibleItems.clear();
        for (DataStore.Record r : getFilteredRecords(queryText.toLowerCase())) {
            StringBuilder row = new StringBuilder();
            for (int i = 0; i < r.values.length; i++) {
                if (i > 0) row.append(" | ");
                row.append(r.values[i]);
            }
            visibleItems.add(row.toString());
        }
        if (adapter != null) adapter.notifyDataSetChanged();
    }

    private void clearInputs() {
        for (EditText input : inputs) input.setText("");
    }
}
