#nobox
export XDG_RUNTIME_DIR=/run/user/$(id -u)
timeout 40 chromium --headless=new --disable-gpu-sandbox --use-angle=gles --user-data-dir=/tmp/ctgpu --virtual-time-budget=8000 --dump-dom chrome://gpu 2>/dev/null | grep -oiE "(Video Decode|video_decode|Hardware accelerated|Software only|Disabled)[^<]{0,80}" | sort | uniq -c | head -20
rm -rf /tmp/ctgpu
