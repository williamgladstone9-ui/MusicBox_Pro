#!/bin/sh
set -eu

if [ "$(id -u)" != "0" ]; then
  echo "Run as root: sudo sh scripts/install.sh"
  exit 1
fi

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

echo "🎵 Installing MusicBox Pro from $ROOT"

apk update || true

# Core packages. Some package names vary by postmarketOS branch, so optional packages use || true.
apk add python3 py3-flask py3-werkzeug nginx mpd mpc alsa-utils pipewire pipewire-pulse wireplumber hostapd dnsmasq avahi openssh ffmpeg curl wget || true
apk add py3-mpd2 || true
apk add librespot || true
apk add shairport-sync || true
apk add icecast || true
apk add usbmuxd libimobiledevice || true

# pip fallback for python-mpd2 if APK package is unavailable.
if ! python3 -c 'import mpd' >/dev/null 2>&1; then
  python3 -m ensurepip || true
  pip3 install python-mpd2 || true
fi

# Users and directories.
addgroup -S music 2>/dev/null || true
adduser -S -G music -h /srv/musicbox music 2>/dev/null || true
addgroup music audio 2>/dev/null || true

mkdir -p /srv/musicbox/{app,config,run,logs,scripts}
mkdir -p /srv/musicbox/music/{library,uploads,playlists}
mkdir -p /srv/musicbox/mpd

cp -r "$ROOT/app"/* /srv/musicbox/app/
cp -r "$ROOT/scripts"/* /srv/musicbox/scripts/
chmod +x /srv/musicbox/scripts/*.sh || true

cp "$ROOT/configs/mpd/mpd.conf" /etc/mpd.conf
mkdir -p /etc/hostapd /etc/dnsmasq.d /etc/nginx/http.d
cp "$ROOT/configs/hostapd/hostapd.conf" /etc/hostapd/hostapd.conf
cp "$ROOT/configs/dnsmasq/musicbox.conf" /etc/dnsmasq.d/musicbox.conf
cp "$ROOT/configs/nginx/musicbox.conf" /etc/nginx/http.d/musicbox.conf

if [ -d /etc/icecast ]; then
  cp "$ROOT/configs/icecast/icecast.xml" /etc/icecast/icecast.xml || true
fi
if [ -d /etc/shairport-sync ]; then
  cp "$ROOT/configs/shairport/shairport-sync.conf" /etc/shairport-sync.conf || true
fi

cp "$ROOT/configs/openrc/musicbox-net" /etc/init.d/musicbox-net
cp "$ROOT/configs/openrc/musicbox-web" /etc/init.d/musicbox-web
cp "$ROOT/configs/openrc/musicbox-librespot" /etc/init.d/musicbox-librespot
cp "$ROOT/configs/openrc/musicbox-live-stream" /etc/init.d/musicbox-live-stream
chmod +x /etc/init.d/musicbox-*

chown -R music:music /srv/musicbox || true
chmod -R g+rwX /srv/musicbox || true

rc-update add musicbox-net default || true
rc-update add hostapd default || true
rc-update add dnsmasq default || true
rc-update add nginx default || true
rc-update add mpd default || true
rc-update add avahi-daemon default || true
rc-update add musicbox-web default || true

cat > /srv/musicbox/config/source-mode <<'MODE'
local
MODE

echo ""
echo "✅ Install complete."
echo ""
echo "Next steps:"
echo "1. Edit WiFi password: /etc/hostapd/hostapd.conf"
echo "2. Start offline AP: sudo sh /srv/musicbox/scripts/mode-offline-ap.sh"
echo "3. Start services: sudo rc-service mpd start; sudo rc-service nginx start; sudo rc-service musicbox-web start"
echo "4. Open: http://musicbox.lan/"
