#timeout 40
tailscale status 2>/dev/null | awk '{print $2, $4, $5, $6, $7, $8}' | cut -c1-110
