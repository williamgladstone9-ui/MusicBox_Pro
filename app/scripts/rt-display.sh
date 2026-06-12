#!/bin/sh
set -eu

# Launch the Surface RT as the main BoatBox helm display.
# Run from a graphical session if available. This is best-effort across postmarketOS setups.

URL="${1:-http://127.0.0.1:8080/display}"

echo "🖥️ Starting Surface RT helm display: $URL"

# Keep screen awake where possible.
setterm -blank 0 -powersave off -powerdown 0 2>/dev/null || true
xset s off -dpms s noblank 2>/dev/null || true

# Prefer lightweight browsers first.
if command -v surf >/dev/null 2>&1; then
  exec surf -F "$URL"
elif command -v chromium-browser >/dev/null 2>&1; then
  exec chromium-browser --kiosk --noerrdialogs --disable-infobars "$URL"
elif command -v chromium >/dev/null 2>&1; then
  exec chromium --kiosk --noerrdialogs --disable-infobars "$URL"
elif command -v firefox-esr >/dev/null 2>&1; then
  exec firefox-esr --kiosk "$URL"
elif command -v firefox >/dev/null 2>&1; then
  exec firefox --kiosk "$URL"
else
  echo "No browser found. Install one: sudo apk add surf    # or firefox-esr"
  echo "Then open: $URL"
  exit 1
fi
