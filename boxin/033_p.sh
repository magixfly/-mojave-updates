curl -s -m 5 -o /dev/null -w "8090 %{http_code}\n" http://192.168.178.235:8090/
curl -s -m 5 -o /dev/null -w "8080 %{http_code}\n" http://127.0.0.1:8080/
cat /proc/net/tcp6 /proc/net/tcp | awk "\$4==\"0A\"{print \$2}"
dumpsys activity activities | grep -E "mResumedActivity|topResumed" | head -3
