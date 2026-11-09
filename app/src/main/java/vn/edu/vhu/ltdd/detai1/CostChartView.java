package vn.edu.vhu.ltdd.detai1;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Color;
import android.util.AttributeSet;
import android.view.View;

public class CostChartView extends View {
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private double fuelCost = 0;
    private double maintenanceCost = 0;

    public CostChartView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public void setCosts(double fuel, double maintenance) {
        fuelCost = fuel;
        maintenanceCost = maintenance;
        invalidate();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        float width = getWidth();
        float height = getHeight();
        float bottom = height - 48;
        float top = 24;
        float max = (float) Math.max(1, Math.max(fuelCost, maintenanceCost));
        float barWidth = width / 5f;

        paint.setColor(Color.DKGRAY);
        paint.setTextSize(32);
        canvas.drawText("So sánh chi phí (VNĐ)", 12, 36, paint);

        float available = bottom - 70;
        float fuelHeight = (float) (fuelCost / max) * available;
        float maintenanceHeight = (float) (maintenanceCost / max) * available;

        paint.setColor(Color.rgb(21, 101, 192));
        canvas.drawRect(width * 0.22f, bottom - fuelHeight, width * 0.22f + barWidth,
                bottom, paint);

        paint.setColor(Color.rgb(46, 125, 50));
        canvas.drawRect(width * 0.62f, bottom - maintenanceHeight, width * 0.62f + barWidth,
                bottom, paint);

        paint.setColor(Color.DKGRAY);
        paint.setTextSize(26);
        canvas.drawText("Nhiên liệu", width * 0.13f, height - 12, paint);
        canvas.drawText("Bảo dưỡng", width * 0.56f, height - 12, paint);
    }
}
