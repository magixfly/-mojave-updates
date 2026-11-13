# Kann die Box Mehrfinger-Touch? (Eingabegeräte mit ABS_MT_*)
adb shell getevent -lp 2>/dev/null | grep -E 'add device|name:|ABS_MT_SLOT|ABS_MT_TRACKING_ID|ABS_MT_POSITION_X' | head -30
adb shell dumpsys input | grep -iE 'touch|multi|Mode|Sources' | head -20
