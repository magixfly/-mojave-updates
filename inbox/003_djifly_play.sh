#screenshot
# DJI Fly (Paket dji.go.v5): schon installiert? Sonst Play-Store-Seite auf der Box öffnen
if adb shell pm list packages | grep -q dji.go.v5; then echo "DJI Fly ist installiert"; adb shell dumpsys package dji.go.v5 | grep versionName
else echo "DJI Fly fehlt – öffne Play Store"; adb shell am start -a android.intent.action.VIEW -d 'market://details?id=dji.go.v5'; sleep 6; fi
