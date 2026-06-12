# 🎵 MusicBox Pro: Surface + 2 iPhones, Spotify + Offline Library

A no-extra-device music system using only:

- Surface RT / Surface-family ARM tablet running postmarketOS
- iPhone 5c / A1532
- iPhone 5s / A1533

It supports:

- Offline local music library on the Surface
- Spotify online through Spotify Connect using `librespot`
- Spotify offline through the official Spotify app on an iPhone using downloaded tracks + AirPlay to the Surface
- Web remote control from either iPhone
- iPhone browser speaker mode for local/Spotify/AirPlay audio, with loose sync
- Surface display / kiosk mode
- Offline standalone WiFi AP mode
- Online modes without buying any extra devices

> Important: True Spotify offline playback directly on the Surface is not realistically available through open-source Linux tools. Spotify offline downloads are DRM-protected and must stay inside the official Spotify app. This project supports Spotify offline by using the iPhone Spotify app as the source, then sending audio to the Surface over AirPlay.

---

## The 3 Music Modes

### 1. Offline Library Mode

No internet required.

```text
Music files on Surface -> MPD -> Surface speakers + iPhone speaker page
```

Use this for MP3, FLAC, AAC, M4A, WAV, OGG, OPUS files uploaded to the Surface.

### 2. Spotify Online Mode

Internet required.

```text
Spotify app on iPhone -> Spotify Connect -> librespot on Surface -> speakers + stream
```

Best when the Surface has internet via:

- home WiFi / existing WiFi, or
- one iPhone's Personal Hotspot, or
- iPhone USB tether while Surface keeps its own MusicBox AP.

Usually requires Spotify Premium for reliable Spotify Connect/librespot use.

### 3. Spotify Offline iPhone Source Mode

No internet required after songs are downloaded in the official Spotify app.

```text
Spotify downloads on iPhone -> AirPlay -> shairport-sync on Surface -> speakers + stream
```

This is the legal/practical way to use Spotify offline with your exact devices.

---

## Main URLs

When using Offline AP mode:

```text
http://musicbox.lan/
http://musicbox.lan/speaker
http://musicbox.lan/display
http://musicbox.lan/stream.mp3
http://musicbox.lan/live.mp3
```

Fallback:

```text
http://192.168.44.1/
http://192.168.44.1/speaker
```

---

## Online/Offline Network Options

### Option A: Offline AP Mode

The Surface creates its own WiFi network:

```text
SSID: MusicBox
IP:   192.168.44.1
```

Works with no internet.

Best for:

- local music files
- Spotify offline downloads from iPhone via AirPlay
- parties with no router

### Option B: Online Hotspot Mode, no extra device

Use one existing iPhone as a Personal Hotspot.

```text
                iPhone 5s Hotspot / Cellular
                         │
             ┌───────────┴───────────┐
             │                       │
          Surface                 iPhone 5c
       librespot/web             controller
```

Best for Spotify online.

### Option C: Surface AP + iPhone USB Tether

Use one existing iPhone over USB for internet while the Surface still hosts the MusicBox WiFi AP.

```text
 iPhone USB tether -> Surface -> MusicBox WiFi AP -> other iPhone
```

This uses no new device, only a cable.

Support depends on postmarketOS kernel packages and iPhone tethering support.

---

## Install

Copy this folder to the Surface, then run:

```sh
cd MusicBox_Pro
sudo sh scripts/install.sh
```

Then configure passwords and start with:

```sh
sudo sh scripts/mode-offline-ap.sh
sudo rc-service musicbox-web start
sudo rc-service mpd start
sudo rc-service nginx start
```

Open on iPhone:

```text
http://musicbox.lan/
```

---

## Recommended Build Order

1. Prove Surface audio works:

```sh
speaker-test -c 2
```

2. Start offline AP:

```sh
sudo sh scripts/mode-offline-ap.sh
```

3. Connect iPhones to `MusicBox`.

4. Start MPD + web:

```sh
sudo rc-service mpd start
sudo rc-service musicbox-web start
sudo rc-service nginx start
```

5. Upload a test MP3 through the web UI.

6. Test speaker mode:

```text
http://musicbox.lan/speaker
```

7. Add Spotify:

```sh
sudo rc-service shairport-sync start
sudo rc-service musicbox-librespot start
```

---

## Spotify Usage

### Spotify Online via Connect

1. Get the Surface online.
2. Start librespot:

```sh
sudo rc-service musicbox-librespot start
```

3. Open Spotify on an iPhone.
4. Tap devices.
5. Choose `MusicBox-Spotify`.

### Spotify Offline via AirPlay

1. Before going offline, download playlists in Spotify on the iPhone.
2. Connect the iPhone to the `MusicBox` WiFi.
3. Start AirPlay receiver:

```sh
sudo rc-service shairport-sync start
```

4. In Spotify on iPhone, play downloaded music.
5. Send audio to AirPlay device `MusicBox AirPlay`.

---

## Important Limits

- Stock iPhones cannot be true Bluetooth speakers.
- Stock iPhones cannot run Snapcast clients.
- Browser speaker mode is loose-sync, not perfect sync.
- Spotify offline on the Surface itself is not provided because Spotify downloads are DRM-protected.
- Old iOS versions may need an older compatible Spotify app already associated with your Apple ID.

---

## Files

```text
app/                  Flask web app
configs/              hostapd, dnsmasq, nginx, MPD, OpenRC, AirPlay, Icecast configs
scripts/              install, network modes, audio mix, status
docs/                 deeper architecture notes
```
