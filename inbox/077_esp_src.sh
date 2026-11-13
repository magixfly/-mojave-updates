# server.py: Stellen mit der seriellen Verbindung zum ESP
cd ~/Bodenstation; ls; grep -n "VERSION\s*=" server.py | head -2
grep -n -iE "serial\.|Serial\(|dtr|rts|ttyACM|by-id|def .*esp|baud" server.py | head -40
grep -n "update" server.py | grep -iE "github|url|raw" | head -5
