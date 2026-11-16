export XDG_RUNTIME_DIR=/run/user/$(id -u)
cat ~/Bodenstation/start.sh | head -40
echo ---journal; journalctl --user -n 25 --no-pager 2>&1 | tail -25
echo ---log; ls -la /tmp/*.log 2>/dev/null; tail -15 ~/Bodenstation/server.log 2>/dev/null; tail -10 /tmp/sm.log 2>/dev/null
