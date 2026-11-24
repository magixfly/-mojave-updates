#timeout 900
curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/setup.sh | bash -s V1.3 2>&1 | tail -25
ls -la /opt/fpv/cockpit
grep -m1 VERSION /opt/fpv/fpvcfg.py
