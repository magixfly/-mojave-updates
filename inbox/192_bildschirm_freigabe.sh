#screenshot
adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; adb shell cat /sdcard/ui.xml > /tmp/ui.xml
python3 - <<'PY'
import re,subprocess
x=open('/tmp/ui.xml',encoding='utf-8',errors='ignore').read()
nodes=re.findall(r'<node [^>]*>',x)
print("Texte:",[re.search(r'text="([^"]*)"',n).group(1) for n in nodes if re.search(r'text="[^"]+"',n)][:30])
for n in nodes:
    t=re.search(r'text="([^"]*)"',n).group(1)
    if re.search(r'(?i)^(start now|jetzt starten|starten|start|allow|zulassen|erlauben)$',t.strip()):
        a,b,c,d=map(int,re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',n).groups())
        subprocess.run(["adb","shell","input","tap",str((a+c)//2),str((b+d)//2)]);print("getippt:",t);break
else: print("keine Freigabe-Taste gefunden")
PY
sleep 3
