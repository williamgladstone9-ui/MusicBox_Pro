#!/bin/sh
set -eu

# Experimental: one existing iPhone provides internet over USB while
# the Surface still hosts the MusicBox AP for the other iPhone.

if [ "$(id -u)" != "0" ]; then
  echo "Run as root: sudo sh mode-online-usb-tether-ap.sh"
  exit 1
fi

echo "🎵 Starting AP + iPhone USB tether mode"
echo "On the iPhone: enable Personal Hotspot, connect by USB, and tap Trust if asked."

rc-service usbmuxd start 2>/dev/null || true
modprobe ipheth 2>/dev/null || true
sleep 3

# Start AP first.
sh /srv/musicbox/scripts/mode-offline-ap.sh

# Find likely iPhone USB interface.
WAN_IF=""
for i in $(ls /sys/class/net); do
  case "$i" in
    eth*|usb*|enx*)
      if [ "$i" != "wlan0" ] && [ "$i" != "lo" ]; then
        WAN_IF="$i"
        break
      fi
      ;;
  esac
done

if [ -z "$WAN_IF" ]; then
  echo "Could not find iPhone USB network interface. Check cable/trust/hotspot/kernel ipheth."
  exit 1
fi

echo "Using $WAN_IF as iPhone tether interface"
udhcpc -i "$WAN_IF" || true

# NAT AP clients out through iPhone tether.
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -C POSTROUTING -o "$WAN_IF" -j MASQUERADE 2>/dev/null || \
  iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE
iptables -C FORWARD -i wlan0 -o "$WAN_IF" -j ACCEPT 2>/dev/null || \
  iptables -A FORWARD -i wlan0 -o "$WAN_IF" -j ACCEPT
iptables -C FORWARD -i "$WAN_IF" -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
  iptables -A FORWARD -i "$WAN_IF" -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT

mkdir -p /srv/musicbox/config
echo online-usb-tether-ap > /srv/musicbox/config/network-mode

echo "✅ AP + USB tether attempted."
echo "MusicBox AP: http://musicbox.lan/"
echo "Internet test from Surface:"
curl -I --max-time 5 https://spotify.com 2>/dev/null | head -3 || true
