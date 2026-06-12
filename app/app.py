#!/usr/bin/env python3
import json
import os
import subprocess
import time
from pathlib import Path

from flask import Flask, jsonify, render_template, request
from werkzeug.utils import secure_filename

try:
    from mpd import MPDClient
except Exception:  # pragma: no cover
    MPDClient = None

BASE = Path(os.environ.get("MUSICBOX_BASE", "/srv/musicbox"))
MUSIC_DIR = BASE / "music" / "library"
UPLOAD_DIR = MUSIC_DIR / "uploads"
CONFIG_DIR = BASE / "config"
LOG_DIR = BASE / "logs"
ALLOWED_EXTENSIONS = {"mp3", "m4a", "aac", "flac", "wav", "ogg", "opus"}
MAX_UPLOAD_MB = int(os.environ.get("MUSICBOX_MAX_UPLOAD_MB", "250"))

for p in (MUSIC_DIR, UPLOAD_DIR, CONFIG_DIR, LOG_DIR):
    p.mkdir(parents=True, exist_ok=True)

app = Flask(__name__, template_folder="templates")
app.config["MAX_CONTENT_LENGTH"] = MAX_UPLOAD_MB * 1024 * 1024


def json_error(message, status=500, **extra):
    payload = {"ok": False, "error": str(message)}
    payload.update(extra)
    return jsonify(payload), status


def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


def get_mpd():
    if MPDClient is None:
        raise RuntimeError("python-mpd2 is not installed")
    client = MPDClient()
    client.timeout = 5
    client.idletimeout = None
    client.connect("127.0.0.1", 6600)
    return client


def mpd_run(func):
    c = None
    try:
        c = get_mpd()
        return func(c)
    finally:
        if c is not None:
            try:
                c.close()
                c.disconnect()
            except Exception:
                pass


def read_text(path, default=""):
    try:
        return Path(path).read_text().strip()
    except Exception:
        return default


def write_text(path, value):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(str(value).strip() + "\n")


def run_cmd(cmd, timeout=4):
    try:
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           timeout=timeout, text=True)
        return {"rc": p.returncode, "out": p.stdout.strip()}
    except Exception as e:
        return {"rc": 99, "out": str(e)}


def service_status(name):
    r = run_cmd(["rc-service", name, "status"], timeout=2)
    out = r["out"]
    return {
        "name": name,
        "ok": r["rc"] == 0,
        "text": out.splitlines()[0] if out else "unknown"
    }


def internet_online():
    # DNS can be unavailable in early boot; test both IP and hostname cheaply.
    r = run_cmd(["sh", "-c", "ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 1 spotify.com >/dev/null 2>&1"], timeout=3)
    return r["rc"] == 0


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/speaker")
def speaker():
    return render_template("speaker.html")


@app.route("/display")
def display():
    return render_template("display.html")


@app.route("/api/status")
def api_status():
    try:
        def op(c):
            return jsonify({"ok": True, "status": c.status(), "song": c.currentsong()})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/library")
def api_library():
    try:
        def op(c):
            return jsonify({"ok": True, "songs": c.listallinfo()})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/playlist")
def api_playlist():
    try:
        def op(c):
            return jsonify({"ok": True, "playlist": c.playlistinfo()})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/search", methods=["POST"])
def api_search():
    data = request.get_json(silent=True) or {}
    query = str(data.get("query", "")).strip()
    if len(query) < 2:
        return jsonify({"ok": True, "results": []})
    try:
        def op(c):
            return jsonify({"ok": True, "results": c.search("any", query)[:100]})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/play", methods=["POST"])
def api_play():
    data = request.get_json(silent=True) or {}
    try:
        def op(c):
            pos = data.get("pos")
            if pos is None:
                c.play()
            else:
                c.play(int(pos))
            return jsonify({"ok": True})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/pause", methods=["POST"])
def api_pause():
    try:
        def op(c):
            c.pause()
            return jsonify({"ok": True})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/stop", methods=["POST"])
def api_stop():
    try:
        def op(c):
            c.stop()
            return jsonify({"ok": True})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/next", methods=["POST"])
def api_next():
    try:
        def op(c):
            c.next()
            return jsonify({"ok": True})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/prev", methods=["POST"])
def api_prev():
    try:
        def op(c):
            c.previous()
            return jsonify({"ok": True})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/volume", methods=["POST"])
def api_volume():
    data = request.get_json(silent=True) or {}
    vol = max(0, min(100, int(data.get("volume", 50))))
    try:
        def op(c):
            c.setvol(vol)
            return jsonify({"ok": True, "volume": vol})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/seek", methods=["POST"])
def api_seek():
    data = request.get_json(silent=True) or {}
    try:
        t = float(data.get("time", 0))
        def op(c):
            c.seekcur(t)
            return jsonify({"ok": True})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/add", methods=["POST"])
def api_add():
    data = request.get_json(silent=True) or {}
    uri = data.get("uri")
    if not uri:
        return json_error("Missing uri", 400)
    try:
        def op(c):
            c.add(uri)
            return jsonify({"ok": True})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/clear", methods=["POST"])
def api_clear():
    try:
        def op(c):
            c.clear()
            return jsonify({"ok": True})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/shuffle", methods=["POST"])
def api_shuffle():
    try:
        def op(c):
            c.shuffle()
            return jsonify({"ok": True})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/repeat", methods=["POST"])
def api_repeat():
    try:
        def op(c):
            s = c.status()
            c.repeat(0 if s.get("repeat") == "1" else 1)
            return jsonify({"ok": True})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/random", methods=["POST"])
def api_random():
    try:
        def op(c):
            s = c.status()
            c.random(0 if s.get("random") == "1" else 1)
            return jsonify({"ok": True})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/crossfade", methods=["POST"])
def api_crossfade():
    data = request.get_json(silent=True) or {}
    seconds = max(0, min(20, int(data.get("seconds", 5))))
    try:
        def op(c):
            c.crossfade(seconds)
            return jsonify({"ok": True, "seconds": seconds})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/outputs")
def api_outputs():
    try:
        def op(c):
            return jsonify({"ok": True, "outputs": c.outputs()})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/output/toggle", methods=["POST"])
def api_output_toggle():
    data = request.get_json(silent=True) or {}
    try:
        output_id = int(data.get("id"))
        enabled = bool(data.get("enabled"))
        def op(c):
            if enabled:
                c.enableoutput(output_id)
            else:
                c.disableoutput(output_id)
            return jsonify({"ok": True})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/api/update", methods=["POST"])
def api_update():
    try:
        def op(c):
            job = c.update()
            return jsonify({"ok": True, "job": job})
        return mpd_run(op)
    except Exception as e:
        return json_error(e, 503)


@app.route("/upload", methods=["POST"])
def upload():
    if "file" not in request.files:
        return json_error("No file part", 400)
    files = request.files.getlist("file")
    saved = []
    rejected = []
    for f in files:
        original = f.filename or ""
        if not original or not allowed_file(original):
            rejected.append(original)
            continue
        filename = secure_filename(original)
        target = UPLOAD_DIR / filename
        base = target.stem
        suffix = target.suffix
        i = 1
        while target.exists():
            target = UPLOAD_DIR / f"{base}_{i}{suffix}"
            i += 1
        f.save(str(target))
        saved.append(str(target.relative_to(MUSIC_DIR)))
    if saved:
        try:
            mpd_run(lambda c: c.update())
        except Exception:
            pass
    return jsonify({"ok": True, "saved": saved, "rejected": rejected})


@app.route("/api/system")
def api_system():
    services = [
        "mpd", "nginx", "musicbox-web", "hostapd", "dnsmasq", "avahi-daemon",
        "shairport-sync", "musicbox-librespot", "icecast", "musicbox-live-stream"
    ]
    return jsonify({
        "ok": True,
        "time": int(time.time()),
        "internet": internet_online(),
        "network_mode": read_text(CONFIG_DIR / "network-mode", "unknown"),
        "source_mode": read_text(CONFIG_DIR / "source-mode", "local"),
        "services": [service_status(s) for s in services],
        "urls": {
            "remote": "/",
            "speaker": "/speaker",
            "display": "/display",
            "mpd_stream": "/stream.mp3",
            "live_stream": "/live.mp3"
        }
    })


@app.route("/api/source", methods=["POST"])
def api_source():
    data = request.get_json(silent=True) or {}
    mode = str(data.get("mode", "local")).strip().lower()
    if mode not in {"local", "spotify-online", "spotify-offline-airplay", "airplay"}:
        return json_error("Invalid source mode", 400)
    write_text(CONFIG_DIR / "source-mode", mode)
    commands = {
        "local": ["sudo rc-service mpd start"],
        "spotify-online": ["sudo rc-service musicbox-librespot start", "Open Spotify app and choose 'MusicBox-Spotify'"],
        "spotify-offline-airplay": ["sudo rc-service shairport-sync start", "Play downloaded Spotify tracks on iPhone and AirPlay to 'MusicBox AirPlay'"],
        "airplay": ["sudo rc-service shairport-sync start", "AirPlay any iPhone audio to 'MusicBox AirPlay'"]
    }
    return jsonify({"ok": True, "mode": mode, "commands": commands[mode]})


@app.route("/api/commands")
def api_commands():
    return jsonify({
        "ok": True,
        "offline_ap": "sudo sh /srv/musicbox/scripts/mode-offline-ap.sh",
        "online_hotspot_client": "sudo sh /srv/musicbox/scripts/mode-online-hotspot-client.sh 'Your iPhone Hotspot' 'password'",
        "online_usb_tether_ap": "sudo sh /srv/musicbox/scripts/mode-online-usb-tether-ap.sh",
        "spotify_online": "sudo rc-service musicbox-librespot start",
        "spotify_offline_airplay": "sudo rc-service shairport-sync start",
        "audio_mix": "sh /srv/musicbox/scripts/setup-audio-mix.sh",
        "live_stream": "sudo rc-service icecast start; sudo rc-service musicbox-live-stream start"
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
