cmd wifi help 2>/dev/null | grep -i -B1 -A2 "tether" | head -30
echo ==; cmd connectivity help 2>/dev/null | head -30
echo ==; service list | grep -i tether
