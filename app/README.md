# ⛵ BoatBox Pro

A boat-focused music system using only:

- Surface RT / Surface-family ARM tablet running postmarketOS
- iPhone 5c / A1532
- iPhone 5s / A1533
- Surface RT 3.5mm headphone jack connected to the boat stereo AUX input

The iPhones act as polished iOS-style remotes. The Surface is the boat audio brain.

---

## What This Version Is Optimized For

This version is no longer trying to make the iPhones act like speakers. For a boat, the clean setup is:

```text
Surface RT headphone jack -> boat stereo AUX input -> boat speakers

iphone 5c -> BoatBox Remote app
iphone 5s -> BoatBox Captain app / Spotify source
```

That is simpler, louder, more reliable, and much easier to use on the water.

---

## Main Features

- Beautiful iOS-style web apps:
  - BoatBox Captain
  - BoatBox Remote
- Add-to-Home-Screen support on iPhone.
- Big wet-finger-friendly controls.
- Sun/night themes for daylight or nighttime boating.
- Huge MUTE button.
- Volume presets:
  - Dock
  - Cruise
  - Party
- Sleep timer.
- Local offline library.
- Spotify Online via Spotify Connect / `librespot`.
- Spotify Offline via official Spotify downloads on iPhone + AirPlay to Surface.
- Surface battery/status page.
- Boat-specific AUX output setup script.
- Offline boat WiFi network.
- Online modes using only existing iPhones, no extra router/device.

---

## Primary URLs

Connect iPhones to the boat WiFi, then open:

```text
http://boatbox.lan/captain
http://boatbox.lan/remote
http://boatbox.lan/ios
```

Fallback if local DNS does not resolve:

```text
http://192.168.44.1/captain
http://192.168.44.1/remote
http://192.168.44.1/ios
```

---

## iOS Apps

These are installable iPhone home-screen apps, not App Store apps. They require no Xcode, no developer account, and no extra hardware.

On each iPhone:

1. Join WiFi: `BoatBox`
2. Open Safari:

```text
http://boatbox.lan/ios
```

3. Open either Captain or Remote.
4. Tap Safari Share.
5. Tap **Add to Home Screen**.
6. Name it:

```text
BoatBox Captain
BoatBox Remote
```

Notes:

- iPhone 5c on iOS 10 may not support modern service-worker caching.
- That is fine. The app shell is served by the Surface over boat WiFi.
- “Offline” means no internet required, not no Surface required.

---

## Music Modes

### 1. Offline Library Mode

No internet required.

```text
Music files on Surface -> MPD -> Surface headphone jack -> boat stereo AUX
```

Upload files from either iPhone using the app.

Supported uploads:

```text
mp3, m4a, aac, flac, wav, ogg, opus
```

### 2. Spotify Online Mode

Internet required.

```text
Spotify app on iPhone -> Spotify Connect -> BoatBox-Spotify -> Surface AUX
```

Usually requires Spotify Premium.

### 3. Spotify Offline Mode

No internet required after downloading playlists in the official Spotify app.

```text
Downloaded Spotify on iPhone -> AirPlay -> BoatBox AirPlay -> Surface AUX
```

This is the realistic/legal way to do Spotify offline because Spotify offline downloads are DRM-protected.

---

## Online Without Extra Devices

### Best Offline Boat Mode

Surface creates the WiFi network:

```text
SSID: BoatBox
IP:   192.168.44.1
```

Works with no marina/router/cell signal.

### Online Hotspot Mode

Use one existing iPhone as a Personal Hotspot:

```text
iPhone hotspot -> Surface + other iPhone remote
```

### USB Tether + BoatBox AP Mode

Use one iPhone by USB for internet while the Surface still runs the BoatBox WiFi network:

```text
iPhone USB tether -> Surface -> BoatBox WiFi -> other iPhone
```

No extra device required. Support depends on iPhone tether/kernel support.

---

## Install

Copy this folder to the Surface, then run:

```sh
cd MusicBox_Pro
sudo sh scripts/install.sh
```

Then edit the WiFi password:

```sh
sudo vi /etc/hostapd/hostapd.conf
```

Look for:

```text
wpa_passphrase=change-this-boat-password
```

---

## Start Boat Mode

Recommended one-command start:

```sh
sudo sh /srv/musicbox/scripts/boat-start.sh
```

This attempts to:

- start offline BoatBox WiFi
- set the Surface headphone/AUX output to safe volume
- start MPD
- start nginx
- start the BoatBox web app
- start AirPlay receiver
- start Spotify Connect if available

---

## Manual Start

```sh
sudo sh /srv/musicbox/scripts/mode-offline-ap.sh
sudo sh /srv/musicbox/scripts/audio-jack-mode.sh
sudo rc-service mpd start
sudo rc-service nginx start
sudo rc-service musicbox-web start
sudo rc-service shairport-sync start
```

Spotify online:

```sh
sudo rc-service musicbox-librespot start
```

---

## Boat Stereo Setup

1. Plug the Surface RT headphone jack into the boat stereo AUX input.
2. Select AUX on the boat stereo.
3. Start BoatBox volume around 35-45%.
4. Raise boat stereo volume gradually.
5. Use BoatBox **MUTE** before unplugging the AUX cable.
6. If you hear distortion, lower Surface volume and raise stereo volume instead.

---

## File Map

```text
app/
  app.py
  templates/
    boat.html        # new beautiful iOS-style Captain/Remote app
    ios.html         # install page for iPhone home-screen apps
    display.html     # Surface display mode
  static/
    manifest.json
    sw.js
    icons/
configs/
  hostapd/           # BoatBox WiFi
  dnsmasq/           # boatbox.lan DNS
  nginx/             # clean URLs
  mpd/               # local library player
  shairport/         # AirPlay receiver
  openrc/            # postmarketOS services
scripts/
  install.sh
  boat-start.sh
  audio-jack-mode.sh
  mode-offline-ap.sh
  mode-online-hotspot-client.sh
  mode-online-usb-tether-ap.sh
  status.sh
```

---

## Important Reality Checks

- Stock iPhones are remotes/sources, not Bluetooth speakers.
- Surface RT headphone jack is the main audio output.
- Spotify offline directly on Linux is not realistic because of Spotify DRM.
- Spotify offline works by playing downloaded tracks inside the official iPhone Spotify app and sending them to the Surface using AirPlay.
- On old iOS, these are best treated as Home Screen web apps rather than native App Store apps.

---

## Surface RT Main Display

The Surface screen is meant to be the main helm display while the iPhones control and pick music.

Start it from the Surface graphical session with:

```sh
sh /srv/musicbox/scripts/rt-display.sh
```

Or manually open a browser on the Surface to:

```text
http://127.0.0.1:8080/display
```

The display shows:

- giant now-playing screen
- progress and volume
- upcoming queue
- source mode
- online/offline state
- Surface battery if available
- iPhone app install URL

The iPhones should use:

```text
http://boatbox.lan/captain
http://boatbox.lan/remote
```

to search, pick songs, add music to the queue, upload music, and change source.
