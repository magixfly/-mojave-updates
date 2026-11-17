cat /proc/device-tree/model; echo; free -m | head -2
hostname -I
curl -s -m 3 http://127.0.0.1:8080/api/state | head -c 60; echo
