#!/usr/bin/env python3
"""Pick the MPRIS music player, ignoring browser tabs (YouTube in the browser, etc.)."""
import json
import subprocess
import sys


def run(*args):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=3, check=False).stdout
    except (OSError, subprocess.TimeoutExpired):
        return ""


# Prefixos de instancia a ignorar. "chromium.instance*" NAO entra: o app do YouTube Music
# (electron) se registra assim no MPRIS. KDE Connect entra porque midia do celular
# pausada assumia o card quando o player do PC pausava.
IGNORED = ("brave", "firefox", "chrome", "google-chrome", "vivaldi", "msedge", "opera", "zen",
           "librewolf", "plasma-browser-integration", "kdeconnect")


def ignored(instance):
    return instance.split(".")[0].lower() in IGNORED


def current():
    fmt = "{{status}}\x1f{{playerInstance}}\x1f{{title}}\x1f{{artist}}\x1f{{mpris:artUrl}}"
    rows = [line.split("\x1f", 4) for line in run("playerctl", "--all-players", "metadata", "--format", fmt).splitlines()]
    rows = [row for row in rows if len(row) == 5 and row[1] and not ignored(row[1])]
    return next((row for row in rows if row[0] == "Playing"), rows[0] if rows else None)


if __name__ == "__main__":
    row = current()
    if len(sys.argv) > 1 and sys.argv[1] in ("previous", "play-pause", "next"):
        if row:
            run("playerctl", "--player", row[1], sys.argv[1])
    else:
        print(json.dumps({"status": row[0], "instance": row[1], "track": row[2], "artist": row[3], "artUrl": row[4]} if row else {}, ensure_ascii=False))
