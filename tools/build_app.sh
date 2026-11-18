#!/bin/bash
# Box-App bauen (Cloud): javac (android-23) → dex → aapt → Attribute patchen (foregroundServiceType, canPerformGestures) → zipalign → signieren
set -e
R=$(cd "$(dirname "$0")/.." && pwd); B=${B:-/home/claude/build}; SDK=/usr/lib/android-sdk/platforms/android-23/android.jar
KS=${KS:-/mnt/user-data/uploads/claude/Carlin/App_1.25/Signatur/ct122.keystore}
mkdir -p $B && cd $B && rm -rf cls classes.dex u.apk u2.apk a.apk CoreTracker.apk px && mkdir cls px
javac --release 8 -nowarn -cp $SDK -d cls $(find $R/app/src -name '*.java')
dalvik-exchange --dex --min-sdk-version=24 --output=classes.dex cls 2>&1 | grep -v JAVA_TOOL || true
aapt package -f -M $R/app/AndroidManifest.xml -S $R/app/res -I $SDK -F u.apk
(cd px && unzip -q ../u.apk AndroidManifest.xml res/xml/a11y.xml && python3 $R/tools/patchattr.py AndroidManifest.xml 0x0101001a 0x01010599 && python3 $R/tools/patchattr.py res/xml/a11y.xml 0x010103d8 0x0101050d)
python3 - <<'P'
import zipfile
src=zipfile.ZipFile('u.apk'); out=zipfile.ZipFile('u2.apk','w')
for n in src.namelist():
    d=src.read(n)
    if n in ('AndroidManifest.xml','res/xml/a11y.xml'): d=open('px/'+n,'rb').read()
    out.writestr(zipfile.ZipInfo(n,(1980,1,1,0,0,0)), d, zipfile.ZIP_STORED if n=='resources.arsc' else zipfile.ZIP_DEFLATED)
out.writestr(zipfile.ZipInfo('classes.dex',(1980,1,1,0,0,0)), open('classes.dex','rb').read(), zipfile.ZIP_DEFLATED)
out.close()
P
zipalign -f 4 u2.apk a.apk
apksigner sign --ks $KS --ks-key-alias CT --ks-pass pass:coretracker --key-pass pass:coretracker --out CoreTracker.apk a.apk 2>&1 | grep -v JAVA_TOOL || true
aapt dump badging CoreTracker.apk | head -1
