#timeout 120
curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/stickpage_1.py -o /opt/fpv/stickpage.py && python3 -m py_compile /opt/fpv/stickpage.py && echo "script ok"
cat > /etc/systemd/system/fpv-stickpage.service <<'UNIT'
[Unit]
Description=FPV: settings page of the LTE stick, passed through the Pi (port 8081)
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/fpv/stickpage.py
Restart=always
RestartSec=5
DynamicUser=yes

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload && systemctl enable --now fpv-stickpage 2>&1 | tail -1
sleep 3; systemctl is-active fpv-stickpage; journalctl -u fpv-stickpage -n 3 --no-pager | cut -c1-160
echo "== through the Pi"; curl -s -m 8 -o /tmp/sp.html -w "http %{http_code} %{size_download} bytes\n" http://127.0.0.1:8081/
grep -io "<title>[^<]*" /tmp/sp.html | head -1; grep -oiE "(src|href)=\"[^\"]+\"" /tmp/sp.html | head -8; grep -ciE "http://192\.168\.100\.1" /tmp/sp.html
echo "== addresses"; ip -br addr | grep -E "wlan0|eth1|tailscale0"
echo "[100%] done"
