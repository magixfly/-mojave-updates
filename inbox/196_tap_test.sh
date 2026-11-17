echo "tap-Antwort: $(curl -s -m 5 'http://192.168.178.235:8090/tap?x=10&y=700')"
echo "key-Antwort: $(curl -s -m 5 'http://192.168.178.235:8090/key?k=none')"
adb shell settings get secure enabled_accessibility_services
adb logcat -d -s CTSS:D CTA11Y:D | tail -8
