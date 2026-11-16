#!/bin/bash
#nobox
curl -s -m 5 "localhost:8080/api/devices?new=1" >/dev/null; sleep 25; curl -s -m 5 localhost:8080/api/devices
