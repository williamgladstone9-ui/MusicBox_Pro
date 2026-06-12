#!/bin/sh
set -eu

# Use this when one existing iPhone is running Personal Hotspot,
# or when you want the Surface to join any existing WiFi.
# No new hardware is required.

if [ "$(id -u)" != "0" ]; then
  echo "Run as root: sudo sh mode-online-hotspot-client.sh 'SSID' 'password'"
  exit 1
fi

SSID="${1:-}"
PASS="${2:-}"

if [ -z "$SSID" ]; then
  echo "Usage: sudo sh mode-online-hotspot-client.sh 'SSID' 'password'"
  exit 1
fi

echo "🎵 Switching Surface to online WiFi client mode: $SSID"

rc-service hostapd stop 2>/dev/null || true
rc-service dnsmasq stop 2>/dev/null || true

cat > /etc/wpa_supplicant/wpa_supplicant.conf <<EOF2
ctrl_interface=/run/wpa_supplicant
update_config=1
country=CA
network={
    ssid="$SSID"
    psk="$PASS"
}
EOF2

ip addr flush dev wlan0 || true
ip link set wlan0 up
wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf || true
udhcpc -i wlan0 || true

rc-service avahi-daemon restart || true
rc-service nginx restart || true

mkdir -p /srv/musicbox/config
echo online-client > /srv/musicbox/config/network-mode

echo "✅ Online client mode attempted."
echo "Surface IPs:"
ip -4 addr show wlan0 | awk '/inet / {print $2}'
echo "Open the Surface IP from the other iPhone, or try http://musicbox.local/"
