package at.magixfly.coretracker;
import android.view.View;
/** Tippen auf "Karten": Download auch während der Fahrt erzwingen – bis zum nächsten Tippen. */
class PillClick implements View.OnClickListener {
    final MainActivity a;
    PillClick(MainActivity a) { this.a = a; }
    public void onClick(View v) { a.tiles.force = !a.tiles.force; a.updatePill(); }
}
