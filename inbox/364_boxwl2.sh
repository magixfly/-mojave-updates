touch /tmp/claude_remote
B=$(adb devices | awk '/:5555[[:space:]]+device/{print $1; exit}'); echo "Box $B"
adb -s $B shell 'which su; ls -l /system/bin/su /system/xbin/su 2>&1; echo == Media; dumpsys wifi | grep -i -E "Media|WRONG_PASSWORD|AUTHENTICATION|DISABLED_" | grep -v -i "mediatek\|multimedia\|MediaStore" | head -20; echo ==; logcat -d -b main,system | grep -i -E "wrong.?password|auth.*fail|Media\"" | tail -10; echo ==; cmd wifi status | grep -m1 "connected to"'
