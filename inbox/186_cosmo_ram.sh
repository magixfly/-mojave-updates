#nobox
python3 tools/cosmows.py 192.168.178.159 '{"cmd":"config_request","param":"system"}' '{"cmd":"config_request","param":"info"}' 2>&1 | grep -iE "mem|ram|model|board|info|cpu" | cut -c1-600 | head
