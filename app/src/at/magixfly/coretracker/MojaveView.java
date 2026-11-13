package at.magixfly.coretracker;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.RectF;
import android.view.View;

/** Kleiner, flüssig drehender Mojave (Bild vom Tracker, sonst gezeichnet). */
class MojaveView extends View {
    volatile Bitmap img;
    final Paint p = new Paint(1);
    final long t0 = System.nanoTime();

    MojaveView(MainActivity a) { super(a); p.setFilterBitmap(true); }

    @Override
    protected void onDraw(Canvas c) {
        float w = getWidth(), h = getHeight(), s = Math.min(w, h);
        float deg = ((System.nanoTime() - t0) / 1e9f * 120f) % 360f;   // 3 s pro Umdrehung
        c.save();
        c.translate(w / 2, h / 2);
        c.rotate(deg);
        Bitmap b = img;
        if (b != null) {
            float bw = b.getWidth(), bh = b.getHeight(), k = s * 0.92f / Math.max(bw, bh);
            c.drawBitmap(b, new Rect(0, 0, (int) bw, (int) bh), new RectF(-bw * k / 2, -bh * k / 2, bw * k / 2, bh * k / 2), p);
        } else {                                   // Ersatz: Truck von oben
            float u = s / 20f;
            p.setColor(0xFF111111);
            for (int i = -1; i <= 1; i += 2) for (int j = -1; j <= 1; j += 2)
                c.drawRoundRect(new RectF(i * 6 * u - 2 * u, j * 5.5f * u - 3 * u, i * 6 * u + 2 * u, j * 5.5f * u + 3 * u), u, u, p);
            p.setColor(0xFFE11D2A);
            c.drawRoundRect(new RectF(-4.5f * u, -8.5f * u, 4.5f * u, 8.5f * u), 2 * u, 2 * u, p);
            p.setColor(0xFF1F2937);
            c.drawRoundRect(new RectF(-3 * u, -3 * u, 3 * u, 2 * u), u, u, p);
        }
        c.restore();
        postInvalidateOnAnimation();
    }
}
