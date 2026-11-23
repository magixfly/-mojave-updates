# Tuning (Freigabe Thorsten 23.11. 22:45): Animationen schneller, TV/Video-Apps duerfen nicht im Hintergrund laufen (oeffnen geht weiter)
settings put global window_animation_scale 0
settings put global transition_animation_scale 0
settings put global animator_duration_scale 0.5
for p in com.google.android.youtube com.netflix.mediaclient com.dazn com.amazon.avod.thirdpartyclient at.tmobile.android.magentatv at.zappn com.mautilus.servus com.audible.application com.google.android.apps.bard com.openai.chatgpt; do
  pm list packages | grep -q "^package:$p$" || continue
  cmd appops set $p RUN_ANY_IN_BACKGROUND ignore && am set-standby-bucket $p restricted 2>/dev/null; am force-stop $p; echo "Hintergrund aus: $p"
done
settings get global window_animation_scale; settings get global transition_animation_scale; settings get global animator_duration_scale
cat /proc/meminfo | head -2
