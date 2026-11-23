# Core Tracker on the Carlin box (without Pi)

Runs the same `bodenstation/server.py` as the Pi, on the box itself (port 8080).
The box app uses it when no Pi is found (App 1.96+).

Folder on the box: `/data/local/tmp/ct`
- `python/` – Python 3.13 (musl build), `ld-musl` – musl loader (Android has no musl)
- `boxmain.py` – DNS fallback for Android, starts `bodenstation/server.py` with `CT_BOX=1`
- `run.sh` – keeps the server running, started by the box app
- `ca.pem` – Android CA certificates for HTTPS

**Status 24.11.2026:** code ready; installing the Python runtime on the box still needs the
user's OK (download of the Python build + musl loader).
