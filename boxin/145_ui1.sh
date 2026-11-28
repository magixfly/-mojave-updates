#screenshot
am start -a android.settings.DATA_USAGE_SETTINGS >/dev/null 2>&1; sleep 3
uiautomator dump /data/local/tmp/ui.xml >/dev/null 2>&1
grep -oE 'text="[^"]+"[^>]*bounds="[^"]+"' /data/local/tmp/ui.xml | sed 's/ resource-id.*bounds=/ bounds=/' | cut -c1-160 | head -30
