#screenshot
adb shell dumpsys activity activities | grep -m2 -E "mResumedActivity|topResumedActivity" | cut -c1-150
