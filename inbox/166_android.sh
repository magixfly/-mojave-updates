adb shell getprop ro.build.version.release; adb shell getprop ro.build.version.sdk
adb shell dumpsys package at.magixfly.coretracker | grep -E "versionName|targetSdk" | head -3
adb shell wm size
