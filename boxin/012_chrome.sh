#screenshot
pm list packages | grep -i -E "chrome|browser|webview" 
am start -a android.intent.action.VIEW -d http://192.168.178.159/ com.android.chrome 2>&1 | tail -1; sleep 12
