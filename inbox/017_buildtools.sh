# Google build-tools laden, nur d8.jar + apksigner.jar hochladen
cd /tmp && rm -rf bt && mkdir bt && cd bt
curl -sSL -o bt.zip https://dl.google.com/android/repository/build-tools_r34-linux.zip; ls -la bt.zip
unzip -o -q bt.zip 'android-14/lib/d8.jar' 'android-14/lib/apksigner.jar' 2>&1 | tail -2
find . -name '*.jar' -exec ls -la {} \;
mkdir -p $HOME/carlin-bridge/outbox/tools && cp $(find . -name d8.jar) $(find . -name apksigner.jar) $HOME/carlin-bridge/outbox/tools/
rm -f bt.zip
