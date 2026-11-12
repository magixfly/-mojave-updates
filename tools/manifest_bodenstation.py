#!/usr/bin/env python3
"""Writes bodenstation/manifest.json for the online update of the CORE TRACKER (Raspberry Pi).
Usage (in the repo folder):  python3 tools/manifest_bodenstation.py 2.0.26 "what is new 1" "what is new 2" ...
The version must be the same as VERSION in bodenstation/server.py."""
import hashlib, json, os, re, sys
base = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "bodenstation")
ver = sys.argv[1]
v = re.search(r'^VERSION = "([^"]+)"', open(os.path.join(base, "server.py")).read(), re.M).group(1)
if v != ver:
    sys.exit("server.py says VERSION %s, not %s" % (v, ver))
fs = []
for root, _, files in os.walk(base):
    for f in sorted(files):
        if f == "manifest.json":
            continue
        p = os.path.relpath(os.path.join(root, f), base).replace(os.sep, "/")
        d = open(os.path.join(root, f), "rb").read()
        fs.append({"p": p, "s": len(d), "md5": hashlib.md5(d).hexdigest()})
json.dump({"ver": ver, "neu": sys.argv[2:], "dateien": fs}, open(os.path.join(base, "manifest.json"), "w"), indent=1)
print("manifest.json:", ver, len(fs), "files")
