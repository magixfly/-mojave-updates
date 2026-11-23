dumpsys meminfo | sed -n "/Total PSS by process/,/Total PSS by OOM/p" | head -30
settings get global window_animation_scale; settings get global transition_animation_scale; settings get global animator_duration_scale
pm list packages -3
