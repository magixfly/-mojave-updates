#nobox
vcgencmd get_throttled; uptime
python3 - <<'P'
import time,urllib.request,math
lat,lon=48.1874,15.6139
for z in (16,17,18):
    n=2**z; x=int((lon+180)/360*n); y=int((1-math.log(math.tan(math.radians(lat))+1/math.cos(math.radians(lat)))/math.pi)/2*n)
    ts=[]
    for dx in range(-2,3):
        for dy in range(-1,2):
            t=time.time()
            try: d=urllib.request.urlopen("http://localhost:8080/tile/%d/%d/%d"%(z,x+dx,y+dy),timeout=20).read(); ok=len(d)
            except Exception as e: ok=str(e)[:30]
            ts.append(time.time()-t)
    print(z,"15 tiles avg %.3fs max %.3fs"%(sum(ts)/len(ts),max(ts)))
P
