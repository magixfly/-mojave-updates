#nobox
touch /tmp/claude_remote
B=192.168.178.235
timeout 2 bash -c "echo > /dev/tcp/$B/5555" 2>/dev/null && echo "5555 offen" || echo "5555 zu"
adb disconnect $B:5555 >/dev/null 2>&1; adb connect $B:5555; sleep 2; adb devices
adb mdns services 2>/dev/null | head
curl -s -m 3 http://$B:8090/state; echo
