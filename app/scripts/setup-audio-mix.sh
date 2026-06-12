#!/bin/sh
set -eu

# Creates a Pulse/PipeWire virtual mix sink so MPD, librespot, and AirPlay
# can all be heard locally and optionally streamed to iPhones.
# Run as the logged-in audio user, not root, if your PipeWire is per-user.

mkdir -p /srv/musicbox/run

REAL_SINK=$(pactl list short sinks | awk '$2 !~ /musicbox_mix/ {print $2; exit}')
if [ -z "${REAL_SINK:-}" ]; then
  echo "No real Pulse/PipeWire sink found. Is PipeWire/Pulse running?"
  exit 1
fi

if ! pactl list short sinks | grep -q musicbox_mix; then
  pactl load-module module-null-sink sink_name=musicbox_mix sink_properties=device.description=MusicBoxMix >/dev/null
fi

# Avoid duplicate loopbacks if possible.
if ! pactl list short modules | grep -q "source=musicbox_mix.monitor"; then
  pactl load-module module-loopback source=musicbox_mix.monitor sink="$REAL_SINK" latency_msec=80 >/dev/null
fi

pactl set-default-sink musicbox_mix
printf '%s\n' musicbox_mix.monitor > /srv/musicbox/run/monitor_source

echo "✅ MusicBox audio mix ready"
echo "Default sink: musicbox_mix"
echo "Loopback to:  $REAL_SINK"
echo "Monitor:      musicbox_mix.monitor"
