#!/bin/sh
set +e

echo "===== MusicBox Status ====="
echo "Date: $(date)"
echo

echo "Network mode: $(cat /srv/musicbox/config/network-mode 2>/dev/null || echo unknown)"
echo "Source mode:  $(cat /srv/musicbox/config/source-mode 2>/dev/null || echo local)"
echo

ip -4 addr show | awk '/^[0-9]+: / {iface=$2} /inet / {print iface, $2}'
echo

for s in hostapd dnsmasq nginx mpd musicbox-web shairport-sync musicbox-librespot icecast musicbox-live-stream; do
  printf '%-24s ' "$s"
  rc-service "$s" status 2>/dev/null | head -1 || echo "not installed/unknown"
done

echo
mpc status 2>/dev/null || true

echo
pactl info 2>/dev/null | grep -E 'Server Name|Default Sink' || true
