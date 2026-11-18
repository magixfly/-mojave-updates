curl -s -m 5 http://127.0.0.1:8080/api/devices | python3 -c "import sys,json;d=json.load(sys.stdin).get('d',{});print('box:',d.get('box'))"
adb shell pidof at.magixfly.coretracker; adb shell dumpsys activity activities | grep -m2 -i "ResumedActivity\|mResumed"
export XDG_RUNTIME_DIR=/run/user/$(id -u); WAYLAND_DISPLAY=wayland-0 grim outbox/261_pi.png
#screenshot
