#!/bin/sh
set -eu

echo "⛵ Starting BoatBox for boat AUX use"

# Offline AP is the most reliable on water.
sh /srv/musicbox/scripts/mode-offline-ap.sh || true

# Prevent display sleep if available.
setterm -blank 0 -powersave off -powerdown 0 2>/dev/null || true
xset s off -dpms s noblank 2>/dev/null || true

# Audio jack best-effort setup.
sh /srv/musicbox/scripts/audio-jack-mode.sh || true

rc-service mpd start || true
rc-service nginx start || true
rc-service musicbox-web start || true
rc-service shairport-sync start || true

# Spotify Connect only works if Surface has internet.
rc-service musicbox-librespot start || true

cat <<MSG
✅ BoatBox is ready.
WiFi:    BoatBox
Captain: http://boatbox.lan/captain or http://192.168.44.1/captain
Remote:  http://boatbox.lan/remote
Install: http://boatbox.lan/ios
Audio:   Surface RT headphone jack -> boat stereo AUX
MSG
