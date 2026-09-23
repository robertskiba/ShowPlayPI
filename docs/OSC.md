# OSC interface

ShowPlayPI can be controlled from any OSC-capable device or program: Bitfocus Companion
("Generic OSC" module), QLab, TouchOSC, lighting consoles, custom scripts …

This file is the **authoritative reference**; the Companion module will be built against it.
Whoever changes or adds a command updates this file in the same commit.

Status: browser mode. Implemented in `rootfs/usr/local/bin/showplaypi-osc`.

## Connection

| | |
|---|---|
| Protocol | OSC 1.0 over **UDP** |
| Target | IP address or hostname of the Pi (default `showplaypi.local`) |
| Port | **9000** (fixed) |
| Replies | none – the Pi currently sends no response |
| Bundles | currently **not** supported, single messages only |
| Argument types | `s` (string), `i` (integer), `f` (float), `T`/`F` (boolean) |
| Enable/disable | `showplaypi.ini` → `[OSC] ENABLED=yes\|no` (takes effect after a restart) |

OSC has no authentication – anyone on the network can send commands. That is intended on isolated event
networks (an optional OSC password is planned, see ROADMAP).

**Everything set via OSC is session-only** – it lasts until the next reboot. No OSC command changes the
configuration file; permanent changes (including a new start page and the operating mode) are only made
through the configuration (configurator, USB drive, SD card, SSH).

Invalid or unknown commands are ignored and logged to the journal:
`journalctl -u showplaypi-osc -f`

## Commands

### `/showplaypi/url <url>`
Shows a URL and makes it the **start page of the current session**. Chromium is restarted for this
(takes about 2–5 s).

| Argument | Type | Description |
|---|---|---|
| url | `s` | must start with `http://`, `https://` or `file://`; may contain umlauts and other non-ASCII characters |

- URLs are converted to their ASCII form before use: international host names to IDNA ("punycode",
  `müller.de` → `xn--mller-kva.de`), non-ASCII characters and spaces in path and query percent-encoded.
  Already encoded URLs stay unchanged. Strings should be UTF-8 (OSC 1.0); Latin-1 is accepted as well.
- The page survives Chromium restarts, watchdog reloads and `/showplaypi/restart`.
- The idle timeout returns to this page.
- It is lost when the **Pi reboots**; afterwards the start page from `showplaypi.ini` is shown again.
- `/showplaypi/home` returns to the start page from `showplaypi.ini` right away.

### `/showplaypi/idle <seconds>`
Enables, changes or disables the idle timeout for the current session: after this time without touch,
mouse or keyboard input the session start page is shown again.

| Argument | Type | Description |
|---|---|---|
| seconds | `i`, `f` or `s` | `0` = off, up to `86400`; fractions are ignored |

- Without this command `[BROWSER] IDLE_TIMEOUT` from `showplaypi.ini` applies.
- `IDLE_ACTION` and `IDLE_CLEAR_SESSION` from `showplaypi.ini` keep applying.
- Takes effect within about 5 seconds; lasts until the next reboot.

### `/showplaypi/home`
Discards the session start page set via `/showplaypi/url` and shows the start page from
`showplaypi.ini` again.
Chromium is restarted for this. No arguments.

### `/showplaypi/refresh`
Reloads the current page (like Ctrl+R). Chromium is not restarted. No arguments.

### `/showplaypi/restart`
Restarts Chromium. The current URL (including a temporary one) is kept.
X11, VNC and the HDMI signal keep running. No arguments – otherwise the command is rejected.

### `/showplaypi/blackout <state>`
Turns the picture black or back on. HDMI signal, resolution and sync are kept, so the display or
projector does not lose the signal.

| Argument | Type | Values |
|---|---|---|
| state | `i`, `f`, `T`/`F` or `s` | black: `1`, `T`, `"1"`, `"on"`, `"yes"`, `"true"` — picture on: `0`, `F`, `"0"`, `"off"`, `"no"`, `"false"` |

The blackout persists across `/showplaypi/url`, `/showplaypi/refresh` and `/showplaypi/restart`.
It is cleared when the kiosk session or the Pi restarts.

## Examples

**Bitfocus Companion** ("Generic OSC" module, target IP of the Pi, port 9000):

| Action | OSC path | Argument |
|---|---|---|
| Show timer | `/showplaypi/url` | string `http://192.168.20.100:4001/timer/` |
| Black picture | `/showplaypi/blackout` | integer `1` |
| Picture on | `/showplaypi/blackout` | integer `0` |
| Reload | `/showplaypi/refresh` | – |

**Command line** (Linux/macOS, package `liblo-tools`):

```bash
oscsend showplaypi.local 9000 /showplaypi/url s "https://example.com"
oscsend showplaypi.local 9000 /showplaypi/blackout i 1
oscsend showplaypi.local 9000 /showplaypi/home
```

**Python** (no extra packages):

```python
import socket

def osc_string(text):
    data = text.encode() + b"\0"
    return data + b"\0" * (-len(data) % 4)

message = osc_string("/showplaypi/url") + osc_string(",s") + osc_string("https://example.com")
socket.socket(socket.AF_INET, socket.SOCK_DGRAM).sendto(message, ("showplaypi.local", 9000))
```

## Planned (see ROADMAP.md)

### Feedback subscription (draft)

Clients register themselves for status feedback, so the return path configures itself – the Companion
module needs no manual "reply to" setting.

- `/showplaypi/subscribe <port> [<ip>]` – register for feedback. Without `<ip>` the Pi replies to the
  source address of the UDP packet (the client does not need to know its own IP); an explicit IP sends
  feedback to another host.
- Several subscribers at the same time (e.g. two Companion instances, or Companion plus a lighting console).
- A subscription **expires** (e.g. after 60 s) unless renewed; clients re-send `subscribe` periodically
  (e.g. every 20 s). This also restores the return path automatically after the Pi reboots.
- Right after subscribing the Pi sends the full status once, afterwards only changes
  (e.g. current URL, blackout, page reachable, mode, version).
- `/showplaypi/unsubscribe [<port>]` – stop feedback.
- Intended for the Companion module and other controllers; not meant for manual use.

### Discovery via Bonjour/mDNS (release 1.0)

The device announces itself on the network, so controllers such as Companion find it without typing an
IP address: `_osc._udp` on port 9000 plus a ShowPlayPI service with TXT records (name, version, mode).

### Display control via HDMI-CEC (release 2.0, draft)

Universal commands for the connected display(s): power on / standby, volume up / down, mute,
input/source selection – with power-state feedback where the display reports it.

### GPIO inputs and outputs (release 2.0, draft)

Inputs (buttons, contact closures) send OSC messages and feedbacks; outputs (relays, lamps) are switched
via OSC and report their state. Pins and names are configured in `showplaypi.ini`.

### Thumbnail (release 2.0, draft)

On request, a small preview image of the current screen is sent to the requesting subscriber (e.g. for a
Companion button). Captured only on request, small and rate limited.

### Audio player (release 2.4, draft)

Optional background service with two sources on the media partition: `audio/` holds **jingles** (single
files on demand), `audio/loop/` the **background playlist** (alphabetical, endless loop). Formats: WAV, MP3,
FLAC, OGG/Opus, M4A/AAC. Files are addressed by file name (`s`) or by number (`i`, 1-based, as in `list`).

| Command | Arguments | Effect |
|---|---|---|
| `/showplaypi/audio/loop/play` | – | start or resume the playlist |
| `/showplaypi/audio/loop/pause` | – | pause the playlist |
| `/showplaypi/audio/loop/stop` | – | stop the playlist (next play starts at the beginning) |
| `/showplaypi/audio/loop/next` / `previous` | – | skip within the playlist |
| `/showplaypi/audio/loop/select` | file name or number | play this playlist entry |
| `/showplaypi/audio/loop/repeat` | `off` \| `all` \| `one` | repeat mode |
| `/showplaypi/audio/loop/shuffle` | `0` \| `1` | shuffle off/on |
| `/showplaypi/audio/loop/volume` | `0`–`100` | playlist volume |
| `/showplaypi/audio/jingle/play` | file name or number | play a jingle once |
| `/showplaypi/audio/jingle/stop` | – | stop the current jingle |
| `/showplaypi/audio/jingle/volume` | `0`–`100` | jingle volume |
| `/showplaypi/audio/volume` | `0`–`100` | master volume |
| `/showplaypi/audio/mute` | `0` \| `1` | master mute |
| `/showplaypi/audio/list` | – | reply with the file lists as JSON (below) |
| `/showplaypi/audio/status` | – | reply with the player state as JSON |

While a jingle plays, the playlist is ducked, paused or keeps playing according to `[AUDIO] JINGLE_MODE`.

Reply to `/showplaypi/audio/list` (sent to the requesting subscriber as an OSC string argument), e.g.:

```json
{
  "jingles": [
    {"number": 1, "file": "01_Opening.wav", "title": "01_Opening", "duration": 8.4},
    {"number": 2, "file": "02_Applause.mp3", "title": "02_Applause", "duration": 12.0}
  ],
  "loop": [
    {"number": 1, "file": "Lounge 01.mp3", "title": "Lounge 01", "duration": 214.5}
  ]
}
```

Reply to `/showplaypi/audio/status`, e.g.:
`{"loop": {"state": "playing", "number": 1, "file": "Lounge 01.mp3", "position": 83.2, "remaining": 131.3,
"volume": 60, "repeat": "all", "shuffle": false}, "jingle": {"state": "stopped"}, "volume": 80, "mute": false}`

Lists larger than one UDP packet (~64 KB) are split into several messages. With a subscription, changes of
the current track, jingle start/stop and the remaining time are sent as feedbacks automatically.

### Further plans

- Status query with a reply to the sender (e.g. current URL, blackout, page reachable) – the basis for
  feedbacks in the Companion module.
- Support for OSC bundles.
- Commands for further modes, e.g. `/video/next`; the naming scheme will be defined with the platform
  rework (phase 2).
