#timeout 90
echo "--- before: Wi-Fi profiles (name, autoconnect priority) ---"
nmcli -t -f NAME,TYPE,AUTOCONNECT-PRIORITY connection show | grep -E "wireless|ethernet"
echo "--- set priorities: Optimus Prime 30, Media 20, XVII 10 (fpv-lte stays 50, but metric 700) ---"
for n in "Optimus Prime:30" "Media:20" "XVII:10"; do
  c="${n%%:*}"; p="${n##*:}"
  if nmcli -t -f NAME connection show | grep -qx "$c"; then nmcli connection modify "$c" connection.autoconnect-priority "$p" && echo "$c -> $p"; else echo "$c: no profile"; fi
done
echo "--- after ---"
nmcli -t -f NAME,TYPE,AUTOCONNECT-PRIORITY,ACTIVE connection show | grep -E "wireless|ethernet"
echo "--- routes ---"
ip -4 route show default
curl -s http://localhost:8080/api/net; echo
echo "--- restart remote maintenance in 20 s (so status.txt shows V1.9.26) ---"
systemd-run --on-active=20 --unit=fpv-remote-restart-095 systemctl restart fpv-remote >/dev/null 2>&1 && echo "scheduled"
echo "[100%] done"
