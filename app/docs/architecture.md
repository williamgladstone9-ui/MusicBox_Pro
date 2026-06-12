# MusicBox Pro Architecture

## Core Idea

Do not force one impossible audio path. Instead, use source modes.

```text
Local Files  -> MPD             ┐
Spotify      -> librespot       ├-> PipeWire/Pulse mix -> Surface speaker
AirPlay      -> shairport-sync  ┘                         └-> optional live stream to iPhones
```

## Source Modes

### Local

MPD controls the library and playlist.

### Spotify Online

`librespot` makes the Surface appear as a Spotify Connect speaker.

### Spotify Offline

The official Spotify app on an iPhone plays downloaded tracks and sends audio to the Surface using AirPlay.

## iPhone Speaker Mode

The iPhone browser plays a stream from the Surface. This is intentionally described as loose-sync.

For MPD-only playback, `/stream.mp3` uses MPD's built-in HTTP stream.

For universal audio capture, `/live.mp3` can point to Icecast fed by the PipeWire/Pulse monitor. This can include MPD, Spotify Connect, or AirPlay audio.

## No Extra Devices

Online access can be provided by either:

1. A WiFi network that already exists.
2. One of the existing iPhones as hotspot.
3. One of the existing iPhones as USB tether while the Surface hosts its own AP.

No new speaker, Raspberry Pi, router, DAC, Chromecast, or computer is required.
