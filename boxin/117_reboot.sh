echo rebooting
setsid sh -c "sleep 5; svc power reboot || reboot" </dev/null >/dev/null 2>&1 &
