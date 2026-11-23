# App 1.88: WLAN-Reihenfolge Media → XVII → Optimus Prime, sonst Hotspot 5 GHz; Test Media mit FRITZ!Box-Passwort
touch /tmp/claude_remote
B=$(adb devices | awk '/:5555[[:space:]]+device/{print $1; exit}'); echo "Box $B"
adb -s $B install -r apk/CoreTracker.apk 2>&1 | tail -1
adb -s $B shell dumpsys package at.magixfly.coretracker | grep -m1 versionName
adb -s $B shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
echo Uz0vZGF0YS9taXNjL2FwZXhkYXRhL2NvbS5hbmRyb2lkLndpZmkvV2lmaUNvbmZpZ1N0b3JlLnhtbAppZiBjbWQgd2lmaSBsaXN0LW5ldHdvcmtzIHwgZ3JlcCAtcSAiIE1lZGlhICI7IHRoZW4gZWNobyAiTWVkaWEgc2Nob24gZ2VzcGVpY2hlcnQiOyBlbHNlClA9JChhd2sgJy88TmV0d29yaz4ve3M9IiJ9IC9uYW1lPSJTU0lEIi97cz0kMH0gL25hbWU9IlByZVNoYXJlZEtleSIvICYmIHMgfiAvT3B0aW11cyBQcmltZS8ge3ByaW50OyBleGl0fScgJFMgfCBzZWQgLWUgJ3MvLio8c3RyaW5nIG5hbWU9IlByZVNoYXJlZEtleSI+JnF1b3Q7Ly8nIC1lICdzLyZxdW90OzxcL3N0cmluZz4uKi8vJyAtZSAncy8mYW1wOy9cJi9nJyAtZSAncy8mbHQ7LzwvZycgLWUgJ3MvJmd0Oy8+L2cnIC1lICJzLyZhcG9zOy8nL2ciKQplY2hvICJQU0stTGFlbmdlOiAkeyNQfSIKY21kIHdpZmkgY29ubmVjdC1uZXR3b3JrIE1lZGlhIHdwYTIgIiRQIgpmb3IgaSBpbiAxIDIgMyA0IDUgNiA3IDggOSAxMCAxMSAxMiAxMyAxNCAxNTsgZG8gc2xlZXAgMjsgY21kIHdpZmkgc3RhdHVzIHwgZ3JlcCAtcSAnY29ubmVjdGVkIHRvICJNZWRpYSInICYmIGJyZWFrOyBkb25lCmlmIGNtZCB3aWZpIHN0YXR1cyB8IGdyZXAgLXEgJ2Nvbm5lY3RlZCB0byAiTWVkaWEiJzsgdGhlbiBlY2hvICJNZWRpYSBPSyBtaXQgUGFzc3dvcnQgdm9uIE9wdGltdXMgUHJpbWUiOyBlbHNlIGVjaG8gIk1lZGlhIGZlaGxnZXNjaGxhZ2VuIC0+IHdpZWRlciB2ZXJnZXNzZW4iOyBpZD0kKGNtZCB3aWZpIGxpc3QtbmV0d29ya3MgfCBhd2sgJyQyPT0iTWVkaWEie3ByaW50ICQxOyBleGl0fScpOyBbIC1uICIkaWQiIF0gJiYgY21kIHdpZmkgZm9yZ2V0LW5ldHdvcmsgJGlkOyBmaQpmaQpjbWQgd2lmaSBzdGF0dXMgfCBncmVwIC1tMSAiY29ubmVjdGVkIHRvIjsgY21kIHdpZmkgbGlzdC1uZXR3b3Jrcwo= | base64 -d | adb -s $B shell 'cat > /data/local/tmp/wl.sh'
adb -s $B shell 'nohup sh /data/local/tmp/wl.sh > /data/local/tmp/wl.log 2>&1 &'
sleep 45; touch /tmp/claude_remote
for i in 1 2 3 4 5 6; do adb connect $B >/dev/null 2>&1; adb -s $B get-state 2>/dev/null | grep -q device && break; sleep 10; done
adb -s $B shell 'cat /data/local/tmp/wl.log; rm -f /data/local/tmp/wl.sh'
