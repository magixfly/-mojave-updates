#screenshot
# Hotspot-Seite öffnen und Bedienelemente auslesen (nichts einschalten)
adb shell am start -a android.settings.TETHER_SETTINGS >/dev/null; sleep 3
adb shell uiautomator dump /sdcard/ui.xml >/dev/null; adb shell cat /sdcard/ui.xml | tr '>' '\n' | grep -oE 'text="[^"]+"|resource-id="[^"]+"|checked="[a-z]+"|bounds="[^"]+"' | paste -sd' ' | sed 's/text=/\n&/g' | head -30
adb shell "dumpsys tethering | grep -iE 'tethering state|softap|wlan|tetherable|Tethered' | head -10"
