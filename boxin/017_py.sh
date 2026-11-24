D=/data/local/tmp/ct; mkdir -p $D; cd $D
R=https://raw.githubusercontent.com/magixfly/-mojave-updates/main/boxpy
U=https://github.com/astral-sh/python-build-standalone/releases/download/20261110/cpython-3.13.18+20261110-aarch64-unknown-linux-musl-install_only_stripped.tar.gz
if [ ! -x python/bin/python3.13 ]; then
  curl -sL -o py.tgz "$U"
  echo "5616ed1d426cb12cc135e5998b42bfd665cf2f9e3f3f9f6c77c73f0ae26f7d03  py.tgz" | sha256sum -c || exit 1
  tar xzf py.tgz && rm py.tgz
fi
curl -sL -o ld-musl $R/ld-musl-aarch64.so.1
echo "ccb91069d0f29f2a94df0762bb567ac6eda819449a269da6777b1e72f1fc2882  ld-musl" | sha256sum -c || exit 1
chmod 755 ld-musl
curl -sL -o boxmain.py $R/boxmain.py; curl -sL -o run.sh $R/run.sh; chmod 755 run.sh
cat /apex/com.android.conscrypt/cacerts/* > ca.pem 2>/dev/null; [ -s ca.pem ] || cat /system/etc/security/cacerts/* > ca.pem
du -sh python; ls -la
export PYTHONHOME=$D/python SSL_CERT_FILE=$D/ca.pem
./ld-musl python/bin/python3.13 -c "
import sys,ssl,socket,json,sqlite3,zlib,hashlib;print(sys.version)
exec(open('boxmain.py').read().split('srv = os.path.join')[0])
print('dns',socket.getaddrinfo('github.com',443,socket.AF_INET)[0][4])
import urllib.request;print('https',urllib.request.urlopen('https://raw.githubusercontent.com/magixfly/-mojave-updates/main/boxpy/README.md',timeout=10).status)
"
