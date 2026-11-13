package at.magixfly.coretracker;
class Task implements Runnable {
    static final int OVERLAY = 1, SEARCH = 2, LOAD = 3, WORKER = 4, TICK = 5, PILL = 6;
    final MainActivity a; final int what; final String text; final int pct;
    Task(MainActivity a, int what, String text, int pct) { this.a = a; this.what = what; this.text = text; this.pct = pct; }
    public void run() {
        if (what == OVERLAY) a.applyOverlay(text, pct);
        else if (what == SEARCH) a.search();
        else if (what == LOAD) a.web.loadUrl(text);
        else if (what == WORKER) a.doSearch();
        else if (what == TICK) a.tick();
        else if (what == PILL) a.updatePill();
    }
}
