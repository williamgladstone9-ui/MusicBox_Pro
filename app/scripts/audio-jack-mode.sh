#!/bin/sh
set -eu

# BoatBox AUX mode: best-effort setup for Surface RT 3.5mm/headphone output.
# Mixer control names vary across kernels, so every command is allowed to fail.

echo "🎧 Setting BoatBox AUX/headphone output mode"

# PipeWire/Pulse volume default. Run as audio user if pactl is per-user.
if command -v pactl >/dev/null 2>&1; then
  SINK=$(pactl get-default-sink 2>/dev/null || true)
  if [ -n "$SINK" ]; then
    pactl set-sink-mute "$SINK" 0 2>/dev/null || true
    pactl set-sink-volume "$SINK" 45% 2>/dev/null || true
    echo "Pulse/PipeWire sink $SINK set to 45%"
  fi
fi

# Common ALSA mixer names.
if command -v amixer >/dev/null 2>&1; then
  for ctl in Master Headphone PCM Speaker Playback; do
    amixer sset "$ctl" unmute 2>/dev/null || true
    amixer sset "$ctl" 45% 2>/dev/null || true
  done
  # Some systems expose an auto-mute switch. Disable if it causes AUX issues.
  amixer sset 'Auto-Mute Mode' Disabled 2>/dev/null || true
fi

cat <<MSG
✅ AUX mode attempted.
Boat stereo setup:
1. Plug Surface RT headphone jack into boat stereo AUX.
2. Set boat stereo to AUX.
3. Start with Surface/BoatBox volume 35-45%.
4. Raise boat stereo volume slowly.
5. Use BoatBox MUTE before unplugging.
MSG
