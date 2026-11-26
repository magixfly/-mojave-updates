#screenshot
cd /data/local/tmp
#screenshot
curl -sL -o ts.apk https://pkgs.tailscale.com/stable/tailscale-android-universal-1.104.7.apk
ls -la ts.apk
pm install -r ts.apk
pm list packages | grep -i tailscale
appops set com.tailscale.ipn ACTIVATE_VPN allow 2>&1
cmd deviceidle whitelist +com.tailscale.ipn 2>&1
settings put secure always_on_vpn_app com.tailscale.ipn
settings put secure always_on_vpn_lockdown 0
monkey -p com.tailscale.ipn -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
rm ts.apk
