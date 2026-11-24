input tap 600 400
which curl wget nc toybox 2>&1 | head
(curl -s --max-time 5 http://192.168.178.214:8080/api/state 2>/dev/null || toybox wget -q -O - http://192.168.178.214:8080/api/state 2>/dev/null) | tr ',' '\n' | grep -E '"hw"|"esp"|"dev"|"fw"|gps_cfg|"ver"' | head -12
