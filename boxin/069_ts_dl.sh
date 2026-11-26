cd /data/local/tmp
curl -sL "https://pkgs.tailscale.com/stable/?mode=json" | grep -o '"[^"]*android[^"]*"' | head -5
curl -sL https://pkgs.tailscale.com/stable/ | grep -o 'tailscale-android[^"]*apk' | sort -u | head -5
