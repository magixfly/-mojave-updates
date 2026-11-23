#nobox
export XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=wayland-0
wlr-randr 2>&1 | head -20
ls ~/.config/kanshi ~/.config/labwc 2>&1; cat ~/.config/kanshi/config 2>/dev/null; grep -i -A3 touch ~/.config/labwc/rc.xml 2>/dev/null
