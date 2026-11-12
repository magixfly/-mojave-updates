#screenshot
# erster Test: Infos der Box
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell wm size
adb shell pm list packages -3
