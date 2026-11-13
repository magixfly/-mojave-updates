# CLAUDE-Abzeichen aus: Schleifen "while true; touch /tmp/claude_remote; sleep 30" aus alten Pi-Connect-Shells beenden
# (das sind Subshells mit Kommandozeile "bash"/"-bash", deren Kind "sleep 30" ist)
for s in $(pgrep -x sleep); do
  a=$(tr '\0' ' ' < /proc/$s/cmdline 2>/dev/null); [ "$a" = "sleep 30 " ] || continue
  p=$(awk '{print $4}' /proc/$s/stat); c=$(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null)
  case "$c" in "-bash "|"bash ") echo "beende Schleife $p ($c)"; kill $p $s;; *) echo "lasse $p ($c)";; esac
done
rm -f /tmp/claude_remote; sleep 35; ls -la /tmp/claude_remote 2>&1
