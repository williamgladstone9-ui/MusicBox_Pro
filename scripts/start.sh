#!/bin/sh
set -eu

echo "🎵 Starting MusicBox Pro"
rc-service mpd start || true
rc-service nginx start || true
rc-service musicbox-web start || true
rc-service shairport-sync start || true
rc-service musicbox-librespot start || true
rc-service icecast start || true
rc-service musicbox-live-stream start || true

echo "✅ Started main services"
echo "Remote:  http://musicbox.lan/"
echo "Speaker: http://musicbox.lan/speaker"
