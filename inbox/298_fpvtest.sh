#nobox
# Player-Test headless (Jmuxer/Janus/Pion), je 30 s
timeout 150 python3 tools/fpvtest.py 192.168.178.175 2>&1 | tail -20
