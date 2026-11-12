#!/bin/bash
# Carlin-Bridge – läuft jede Minute am Pi (corepi).
# Holt Befehle aus GitHub (Branch "carlin", Ordner inbox/), führt sie per ADB
# auf der Carlin-Box aus und lädt Ausgabe + Screenshot nach outbox/ hoch.
set -u
D="$HOME/carlin-bridge"
cd "$D" || exit 1
. "$HOME/adbx/env.sh"
CFG_BOX_IP=172.20.10.14; BOX_PORT=5555; HEARTBEAT_MIN=30; CMD_TIMEOUT=600
BOX_IP=$CFG_BOX_IP
[ -f config.txt ] && . ./config.txt
T="$BOX_IP:$BOX_PORT"
log(){ echo "$(date '+%F %T') $*" >> "$HOME/carlin-bridge.log"; }

is_dev(){ adb devices | grep -q "^$T[[:space:]]*device"; }

connect_box(){
  is_dev && return 0
  adb connect "$T" >/dev/null 2>&1; sleep 1
  is_dev && return 0
  # Box neu gestartet -> zufälliger Port: per mDNS (Netzwerk-Suche) finden
  local s; s=$(adb mdns services 2>/dev/null | awk '/_adb-tls-connect/{print $NF}' | head -1)
  if [ -n "$s" ]; then
    adb connect "$s" >/dev/null 2>&1; sleep 2
    adb -s "$s" tcpip "$BOX_PORT" >/dev/null 2>&1; sleep 3
    adb connect "$T" >/dev/null 2>&1; sleep 1
  fi
  is_dev
}

# Status
if connect_box; then ST="verbunden ($T)"; else ST="NICHT erreichbar ($T)"; fi
export ANDROID_SERIAL="$T"

changed=0
for f in inbox/*.sh; do
  [ -e "$f" ] || continue
  n=$(basename "$f" .sh)
  [ -e "outbox/$n.log" ] && continue
  if ! is_dev; then log "$n wartet – Box nicht erreichbar"; break; fi
  log "starte $n"
  { echo "### $n  –  $(date '+%F %T')"; echo "### Box: $ST"; echo;
    cd "$D"; timeout "$CMD_TIMEOUT" bash "$f" 2>&1; rc=$?; echo; echo "### Exit-Code: $rc"; } > "outbox/$n.log"
  if grep -q '^#screenshot' "$f"; then
    adb exec-out screencap -p > "outbox/$n.png" 2>/dev/null || rm -f "outbox/$n.png"
  fi
  changed=1
done

# Lebenszeichen
now=$(date +%s); last=$(cat "$HOME/.carlin-hb" 2>/dev/null || echo 0)
old=$(sed -n 2p outbox/status.txt 2>/dev/null)
if [ "$old" != "Box: $ST" ] || { [ "$HEARTBEAT_MIN" -gt 0 ] && [ $((now-last)) -ge $((HEARTBEAT_MIN*60)) ]; }; then
  printf 'Stand: %s\nBox: %s\nPi: %s\n' "$(date '+%F %T')" "$ST" "$(hostname -I | awk '{print $1}')" > outbox/status.txt
  echo "$now" > "$HOME/.carlin-hb"; changed=1
fi

if [ "$changed" = 1 ]; then
  git add -A outbox
  git -c user.name=corepi -c user.email=corepi@local commit -qm "corepi: Ergebnisse $(date '+%F %T')" && \
  { git push -q origin HEAD:carlin 2>>"$HOME/carlin-bridge.log" || { git pull -q --rebase origin carlin && git push -q origin HEAD:carlin; } ; }
fi
