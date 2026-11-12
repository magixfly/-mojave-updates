# Android-Bauwerkzeuge (Java, plattformunabhängig) aus Debian holen und hochladen
mkdir -p /tmp/abt && cd /tmp/abt && rm -f *.deb
for p in dalvik-exchange d8 r8 apksigner android-sdk-platform-23 libandroid-23-java android-libdx-java; do
  echo "== $p: $(apt-cache policy $p 2>/dev/null | sed -n 2p)"
done
apt-get download dalvik-exchange android-sdk-platform-23 apksigner 2>&1 | tail -3
apt-cache depends dalvik-exchange apksigner | grep Depends
ls -la /tmp/abt
mkdir -p $HOME/carlin-bridge/outbox/tools && cp /tmp/abt/*.deb $HOME/carlin-bridge/outbox/tools/ 2>/dev/null
du -sh $HOME/carlin-bridge/outbox/tools
