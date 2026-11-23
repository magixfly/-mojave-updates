#nobox
cd ~/Bodenstation; du -sh tiles tiles/* 2>/dev/null; find tiles -type f | wc -l; ls rides 2>/dev/null | wc -l
curl -s localhost:8080/api/state | python3 -c "import json,sys;print(json.load(sys.stdin).get(\"box\"))"
