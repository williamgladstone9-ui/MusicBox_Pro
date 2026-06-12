#!/bin/sh
set -eu

if [ "$(id -u)" != "0" ]; then
  echo "Run as root: sudo sh mode-offline-ap.sh"
  exit 1
fi

echo "🎵 Switching to MusicBox Offline AP mode"

# Stop client network managers if present. Ignore failures.
rc-service networkmanager stop 2>/dev/null || true
rc-service wpa_supplicant stop 2>/dev/null || true

ip link set wlan0 up
ip addr flush dev wlan0 || true
ip addr add 192.168.44.1/24 dev wlan0

rc-service dnsmasq restart || true
rc-service hostapd restart || true
rc-service avahi-daemon restart || true
rc-service nginx restart || true

mkdir -p /srv/musicbox/config
echo offline-ap > /srv/musicbox/config/network-mode

echo "✅ Offline AP ready"
echo "SSID: MusicBox"
echo "URL:  http://musicbox.lan/ or http://192.168.44.1/"
