#screenshot
ip addr | grep "inet "
dumpsys connectivity | grep -o "VPN[^,]*" | head -3
settings get secure always_on_vpn_app
