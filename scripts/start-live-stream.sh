#!/bin/sh
set -eu

MONITOR="${MUSICBOX_MONITOR:-musicbox_mix.monitor}"
PASSWORD="${ICECAST_SOURCE_PASSWORD:-musicbox-source}"
MOUNT="${ICECAST_MOUNT:-musicbox.mp3}"

if [ -f /srv/musicbox/run/monitor_source ]; then
  MONITOR="$(cat /srv/musicbox/run/monitor_source)"
fi

echo "Starting live stream from $MONITOR to Icecast /$MOUNT"

exec ffmpeg -nostdin -hide_banner -loglevel warning \
  -f pulse -i "$MONITOR" \
  -ac 2 -ar 44100 -b:a 160k -content_type audio/mpeg \
  -f mp3 "icecast://source:${PASSWORD}@127.0.0.1:8000/${MOUNT}"
