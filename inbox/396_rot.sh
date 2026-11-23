#nobox
export XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=wayland-0
cp ~/.config/kanshi/config ~/.config/kanshi/config.v345
sed -i "s/output DSI-1 enable mode 720x1280@60.038 position 0,0 transform 90/output DSI-1 enable mode 720x1280@60.038 position 0,0 transform 270/" ~/.config/kanshi/config
grep "transform" ~/.config/kanshi/config
wlr-randr --output DSI-1 --transform 270 && wlr-randr | grep Transform
