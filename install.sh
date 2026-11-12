#!/bin/bash
# Einmalige Einrichtung am Pi (ohne sudo): Runner + Cron-Eintrag (jede Minute)
set -e
cat > "$HOME/carlin-run.sh" <<'R'
#!/bin/bash
# holt die neueste Bridge + Befehle von GitHub und startet sie
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/carlin_deploy -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
cd "$HOME/carlin-bridge" || exit 1
git fetch -q origin carlin && git reset -q --hard origin/carlin
exec bash bridge.sh
R
chmod +x "$HOME/carlin-run.sh"
L='* * * * * flock -n /tmp/carlin.lock $HOME/carlin-run.sh >/dev/null 2>&1'
( crontab -l 2>/dev/null | grep -v carlin-run.sh; echo "$L" ) | crontab -
echo "Carlin-Bridge installiert:"; crontab -l | grep carlin
