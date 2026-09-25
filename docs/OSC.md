# OSC interface

ShowPlayPI can be controlled from any OSC-capable device or program: Bitfocus Companion
("Generic OSC" module), QLab, TouchOSC, lighting consoles, custom scripts …

This file is the **authoritative reference**; the Companion module will be built against it.
Whoever changes or adds a command updates this file in the same commit.

Status: browser mode; video, Companion, Ontime and audio as a first version (see below). Implemented in
`rootfs/usr/local/bin/showplaypi-osc` and `showplaypi-video`.

## Connection

| | |
|---|---|
| Protocol | OSC 1.0 over **UDP** |
| Target | IP address or device name of the Pi, e.g. `showplaypi-e84042.local` (shown on the setup page) |
| Port | **23878** (fixed; chosen so that it does not collide with the default ports of common show-control software) |
| Replies | none – except `/showplaypi/video/list`, `/showplaypi/video/status`, `/showplaypi/audio/list`, `/showplaypi/audio/status` and `/showplaypi/companion/emulators`, which answer to the sender's address and port |
| Bundles | currently **not** supported, single messages only |
| Argument types | `s` (string), `i` (integer), `f` (float), `T`/`F` (boolean) |
| Times | always in **milliseconds** (fades, durations, positions, timeouts); volumes always in **percent** |
| Enable/disable | `showplaypi.ini` → `[OSC] ENABLED=yes\|no` (takes effect after a restart) |

OSC has no authentication – anyone on the network can send commands. That is intended on isolated event
networks (an optional OSC password is planned, see ROADMAP).

**Everything set via OSC is session-only** – it lasts until the next reboot. No OSC command changes the
configuration file; permanent changes (including a new start page and the operating mode) are only made
through the configuration (configurator, USB drive, SD card, SSH).

Invalid or unknown commands are ignored and logged to the journal:
`journalctl -u showplaypi-osc -f`

### Naming scheme

| Address | Scope |
|---|---|
| `/showplaypi/<command>` | every mode (e.g. `blackout`, the feedback subscription) |
| `/showplaypi/browser/…` | every mode with the browser: `browser`, `ontime` and `companion` (unless the browser is switched off) |
| `/showplaypi/video/…` | video mode (`[SYSTEM] MODE=video`) |
| `/showplaypi/companion/…` | Companion mode (`[SYSTEM] MODE=companion`) |
| `/showplaypi/ontime/…` | Ontime mode (`[SYSTEM] MODE=ontime`) |
| `/showplaypi/audio/…` | audio player, an optional extra in every mode (`[AUDIO] ENABLED=yes`) |

**Commands of an inactive mode or service are ignored** (and logged): the browser commands only act where the
browser runs (browser, Ontime and Companion mode), the video, Companion and Ontime commands only in their
mode, the audio commands only while the audio player is enabled. There is no error reply; the status feedback reports the active mode and services, so a controller
can grey out what is not available.

## Commands – browser (browser, Ontime and Companion mode)

### `/showplaypi/browser/url <url>`
Shows a URL and makes it the **start page of the current session**. Chromium is restarted for this
(takes about 2–5 s).

| Argument | Type | Description |
|---|---|---|
| url | `s` | must start with `http://`, `https://` or `file://`; may contain umlauts and other non-ASCII characters |

- URLs are converted to their ASCII form before use: international host names to IDNA ("punycode",
  `müller.de` → `xn--mller-kva.de`), non-ASCII characters and spaces in path and query percent-encoded.
  Already encoded URLs stay unchanged. Strings should be UTF-8 (OSC 1.0); Latin-1 is accepted as well.
- The page survives Chromium restarts, watchdog reloads and `/showplaypi/browser/restart`.
- The idle timeout returns to this page.
- It is lost when the **Pi reboots**; afterwards the start page from `showplaypi.ini` is shown again.
- `/showplaypi/browser/home` returns to the start page from `showplaypi.ini` right away.

### `/showplaypi/browser/idle <milliseconds>`
Enables, changes or disables the idle timeout for the current session: after this time without touch,
mouse or keyboard input the session start page is shown again.

| Argument | Type | Description |
|---|---|---|
| milliseconds | `i`, `f` or `s` | `0` = off, up to `86400000` (24 hours); e.g. `120000` = 2 minutes; rounded up to whole seconds |

- Without this command `[BROWSER] IDLE_TIMEOUT` from `showplaypi.ini` applies.
- `IDLE_ACTION` and `IDLE_CLEAR_SESSION` from `showplaypi.ini` keep applying.
- Takes effect within about 5 seconds; lasts until the next reboot.

### `/showplaypi/browser/home`
Discards the session start page set via `/showplaypi/browser/url` and shows the start page from
`showplaypi.ini` again.
Chromium is restarted for this. No arguments.

### `/showplaypi/browser/refresh`
Reloads the current page (like Ctrl+R). Chromium is not restarted. No arguments.

### `/showplaypi/browser/restart`
Restarts Chromium. The current URL (including a temporary one) is kept.
X11, VNC and the HDMI signal keep running. No arguments – otherwise the command is rejected.

## Commands – every mode

### `/showplaypi/blackout <state>`
Turns the picture black or back on. HDMI signal, resolution and sync are kept, so the display or
projector does not lose the signal.

| Argument | Type | Values |
|---|---|---|
| state | `i`, `f`, `T`/`F` or `s` | black: `1`, `T`, `"1"`, `"on"`, `"yes"`, `"true"` — picture on: `0`, `F`, `"0"`, `"off"`, `"no"`, `"false"` |

The blackout persists across `/showplaypi/browser/url`, `/showplaypi/browser/refresh` and
`/showplaypi/browser/restart`. It is cleared when the kiosk session or the Pi restarts.

In **video mode** the player fades its own picture: `/showplaypi/blackout <state> [fade]`, `fade` in
milliseconds (default: `[VIDEO] FADE`).

**Planned (release 1.1):** the blackout always fades – `/showplaypi/blackout <state> [fade]`, `fade` in
milliseconds for this command; the default comes from `showplaypi.ini` (e.g. `[DISPLAY] BLACKOUT_FADE=500`,
`0` = hard cut). Today the picture switches immediately.

## Examples

**Bitfocus Companion** ("Generic OSC" module, target IP of the Pi, port 23878):

| Action | OSC path | Argument |
|---|---|---|
| Show timer | `/showplaypi/browser/url` | string `http://192.168.20.100:4001/timer/` |
| Black picture | `/showplaypi/blackout` | integer `1` |
| Picture on | `/showplaypi/blackout` | integer `0` |
| Reload | `/showplaypi/browser/refresh` | – |

A ready-made page is in the `PRESETS` folder of the SHOWPLAYPI drive
(`ShowPlayPI Companion Demo.companionconfig`).

**Command line** (Linux/macOS, package `liblo-tools`):

```bash
oscsend showplaypi-e84042.local 23878 /showplaypi/browser/url s "https://example.com"
oscsend showplaypi-e84042.local 23878 /showplaypi/blackout i 1
oscsend showplaypi-e84042.local 23878 /showplaypi/browser/home
```

**Python** (no extra packages):

```python
import socket

def osc_string(text):
    data = text.encode() + b"\0"
    return data + b"\0" * (-len(data) % 4)

message = osc_string("/showplaypi/browser/url") + osc_string(",s") + osc_string("https://example.com")
socket.socket(socket.AF_INET, socket.SOCK_DGRAM).sendto(message, ("showplaypi-e84042.local", 23878))
```

## Planned (see ROADMAP.md)

### Feedback subscription (release 1.2, draft)

Clients register themselves for status feedback, so the return path configures itself – the Companion
module needs no manual "reply to" setting.

- `/showplaypi/subscribe <port> [<ip>]` – register for feedback. Without `<ip>` the Pi replies to the
  source address of the UDP packet (the client does not need to know its own IP); an explicit IP sends
  feedback to another host.
- Several subscribers at the same time (e.g. two Companion instances, or Companion plus a lighting console).
- A subscription **expires** (e.g. after 60 s) unless renewed; clients re-send `subscribe` periodically
  (e.g. every 20 s). This also restores the return path automatically after the Pi reboots.
- **Handshake:** right after subscribing the Pi answers with `/showplaypi/hello` and a JSON string that
  tells the controller what it is talking to, e.g.

  ```json
  {"product": "ShowPlayPI", "version": "1.0.0", "api": 1, "name": "showplaypi-e84042",
   "model": "Raspberry Pi 5", "mode": "browser", "services": ["audio"]}
  ```

  `mode` and `services` let the Companion module offer only the actions and presets that work right now
  (commands of inactive modes are ignored anyway); `api` is the version of this OSC interface, so a newer
  module can handle devices with older software. The mode only changes through the configuration and
  therefore with a restart – the renewed subscription after the restart brings a new `hello`.
- After the handshake the Pi sends the full status once and the file lists of the active mode and services
  (see below), afterwards only changes (e.g. current URL, blackout, page reachable).
- `/showplaypi/unsubscribe [<port>]` – stop feedback.
- Intended for the Companion module and other controllers; not meant for manual use.

### Commands for every mode (release 1.2, draft)

| Command | Arguments | Effect |
|---|---|---|
| `/showplaypi/identify` | `[ms]` | shows device name, IP address and version large on the screen for `ms` milliseconds (default `5000`), over whatever is playing – to find out which display is which device |
| `/showplaypi/status` | `[port]` | replies to the sender (its IP address, the given port or else the source port) with `/showplaypi/status` and the complete state as JSON: the `hello` information plus the state of the active mode and services (e.g. current URL, blackout, page reachable; for video and audio as in `…/status` below) |
| `/showplaypi/system` | `[port]` | replies to the sender (like `status`) with `/showplaypi/system` and the load of the device as JSON (below) |
| `/showplaypi/reboot` | `"reboot"` | restarts the device (emergency); only with the word `reboot` as argument, so a misconfigured button cannot restart the device by accident |

`/showplaypi/blackout` (above) works in every mode as well.

Reply to `/showplaypi/system`, e.g.:

```json
{"cpu": 23, "cores": [30, 18, 25, 19], "ram": {"used": 812, "total": 4096, "percent": 20},
 "temperature": 54.2, "throttled": {"undervoltage": false, "now": false, "since_boot": false},
 "uptime": 5423000, "drives": {"system": {"free": 7340}, "media": {"free": 2890}}}
```

CPU load in percent (total and per core, averaged over the last second), RAM and free space in MB,
temperature in °C, `throttled` from the firmware (under-voltage, throttling now or since the start), uptime
in milliseconds.

### File lists (release 1.2, draft)

Video player, jingles and audio playlists report their files as a **JSON array**, e.g. for dropdowns in the
Companion module:

- sent to every subscriber **after the handshake** and **whenever files change** (added, removed or
  renamed on the SHOWPLAYPI drive – over USB, the network share or a card reader), and to the requester on
  `…/list`
- files are numbered from 1 in alphabetical order; commands accept the number (`i`) or the file name (`s`,
  case-insensitive, with or without extension)
- every entry: `number`, `file`, `title` (file name without extension) and `duration` in milliseconds
- lists larger than one UDP packet (~64 KB, several hundred files) are split into several messages
  (`part` and `parts` in the JSON)

### Discovery via Bonjour/mDNS (release 1.1)

The device announces itself on the network, so controllers such as Companion find it without typing an
IP address: `_osc._udp` on port 23878 plus a ShowPlayPI service with TXT records (name, version, mode).

### Display control via HDMI-CEC (release 2.2, draft)

Universal commands for the connected display(s): power on / standby, volume up / down, mute,
input/source selection – with power-state feedback where the display reports it.

### GPIO inputs and outputs (release 2.2, draft)

Inputs (buttons, contact closures) send OSC messages and feedbacks; outputs (relays, lamps) are switched
via OSC and report their state. Pins and names are configured in `showplaypi.ini`.

### Thumbnail (release 2.2, draft)

On request, a small preview image of the current screen is sent to the requesting subscriber (e.g. for a
Companion button). Captured only on request, small and rate limited.

### Video mode (`[SYSTEM] MODE=video`)

**First version implemented** (`showplaypi-video`, mpv): all commands in the tables below; `list` and
`status` answer to the sender. Not yet: crossfades (transitions fade through black), feedbacks for
subscribers, and video durations in the file list before a video has played once (`null` until then).


Full-screen player for **videos and still images** (JPG, PNG, WebP) from the SHOWPLAYPI drive – mixed, or
only images as a slideshow:

- `VIDEO/` is always playlist 1 and the default; its subfolders follow as playlists 2, 3, … in alphabetical
  order (one level, deeper folders are ignored), e.g. `VIDEO/Morning/`, `VIDEO/Noon/`. The start playlist can
  be set in `showplaypi.ini`.
- **Default:** playlist 1 **starts automatically** after the device has started, and its files play in
  alphabetical order in an endless loop – no command needed. With `[VIDEO] AUTOSTART=no` the player waits
  (black) for `play` or `cue`.
- Transitions between entries are a **crossfade** by default (`[VIDEO] TRANSITION=crossfade|black`);
  `stop` and the end of a playlist played once always fade to black. `[fade]` is an optional fade time in
  **milliseconds** (`i`); without it the default from `showplaypi.ini` applies.
- Still images are always scaled – up or down, never distorted – to the full height or the full width of the
  screen, whichever is reached first; black bars remain where the aspect ratio differs (`[VIDEO] STILL_FIT=fit`,
  default). With `fill` they fill the screen and are cropped. Portrait photos are rotated according to their
  EXIF orientation.
- A still image stays for the default duration from `showplaypi.ini`, or for the duration in its file name,
  e.g. `020_Sponsors [15sec].jpg` (also `[15s]`).
  For a still image, elapsed time, remaining time and the playhead refer to its display duration.
- Volumes are always in percent (`0`–`100`). Everything set via OSC lasts until the next reboot.

**Playback**

| Command | Arguments | Effect |
|---|---|---|
| `/showplaypi/video/play` | `[fade]` | start or resume |
| `/showplaypi/video/pause` | – | pause: a video holds its frame, a still image stays and its timer stops |
| `/showplaypi/video/toggle` | – | play/pause (one button in Companion) |
| `/showplaypi/video/stop` | `[fade]` | fade to black and stay black (the HDMI signal is kept); the next play starts at the beginning |
| `/showplaypi/video/next` / `previous` | `[fade]` | next or previous entry |
| `/showplaypi/video/restart` | – | play the current entry from the beginning |
| `/showplaypi/video/playhead` | milliseconds | set the playhead of the current entry, counted from its start (e.g. `30000` = 0:30); playing stays playing, paused stays paused |
| `/showplaypi/video/playhead/end` | milliseconds | set the playhead counted back from the end (e.g. `10000` = T-10 s) |
| `/showplaypi/video/select` | number or file name `[fade]` | jump to this entry and play it |
| `/showplaypi/video/cue` | number or file name | prepare an entry: show its first frame and wait – `play` starts it without delay (e.g. a walk-in video on cue) |
| `/showplaypi/video/playlist` | playlist name or number `[fade]` | switch playlist (`VIDEO` = playlist 1); starts with its first entry |
| `/showplaypi/video/repeat` | `all` \| `one` \| `off` | loop the playlist (default), loop the current entry, or play the playlist once; at the end it always fades to black |

**Session settings**

| Command | Arguments | Effect |
|---|---|---|
| `/showplaypi/video/fade` | milliseconds | default fade time |
| `/showplaypi/video/stillduration` | milliseconds | default duration of still images (a tag in the file name wins) |
| `/showplaypi/video/volume` | `0`–`100` `[fade]` | volume of the videos in percent |
| `/showplaypi/video/mute` | `0` \| `1` \| `toggle` | mute |
| `/showplaypi/video/list` | – | send the file list (below) to the requester |
| `/showplaypi/video/status` | – | send the player state as JSON to the requester |

File list `/showplaypi/video/files` (after the handshake, on changes and on `list`), e.g.:

```json
{
  "playlists": [
    {"number": 1, "name": "VIDEO", "default": true, "entries": [
      {"number": 1, "file": "010_Intro.mp4", "title": "010_Intro", "type": "video", "duration": 42000},
      {"number": 2, "file": "020_Sponsors [15sec].jpg", "title": "020_Sponsors", "type": "still", "duration": 15000}
    ]},
    {"number": 2, "name": "Morning", "default": false, "entries": []}
  ]
}
```

**Feedbacks** for subscribers (on change): `…/video/state` (`playing` \| `paused` \| `cued` \| `stopped`),
`…/video/playlist`, `…/video/item` (number, title, type), `…/video/elapsed` and `…/video/remaining`
(milliseconds of the current entry – e.g. a countdown on a button), volume and mute. Elapsed and remaining
time are sent once per second while playing and immediately on start, pause and every playhead change.

### Companion mode (`[SYSTEM] MODE=companion`)

Browser mode plus Bitfocus Companion running on the device (native, `/opt/companion`): the kiosk browser
always starts with Companion's **emulator chooser**, and all browser commands work (e.g.
`/showplaypi/browser/home` returns to the chooser, `/showplaypi/browser/url` shows any other page). The
admin interface is at `http://<device name>.local:8000`. Pressing buttons, switching pages or setting
variables is done through **Companion's own OSC and HTTP interfaces** – ShowPlayPI does not duplicate them.
Companion's own OSC receiver is off by default (port `12321` when enabled); it must not be set to
ShowPlayPI's port `23878`.

**First version implemented:** `emulators`, `emulator`, `tablet`, `restart`. Not yet: `backup`, feedbacks.

| Command | Arguments | Effect |
|---|---|---|
| `/showplaypi/companion/emulators` | `[port]` | replies to the sender (its source port, or `port`) with `/showplaypi/companion/emulators` and the list of all emulators as JSON – e.g. for a dropdown in the Companion module |
| `/showplaypi/companion/emulator` | `[id or name]` | without an argument: the emulator chooser; with the ID or the name of an emulator (case-insensitive): this emulator |
| `/showplaypi/companion/tablet` | `[pages] [columns] [rows]` | the web buttons view: optionally only certain pages (`3`, or `"1,2"` as a string) in a grid of `columns` × `rows` buttons – e.g. `3 4 2` = page 3 with 4 × 2 buttons for a small touch screen; the buttons are scaled to the screen by Companion |
| `/showplaypi/companion/restart` | – | restart Companion (e.g. if it hangs); the browser reconnects by itself |
| `/showplaypi/companion/backup` | – | *planned:* create a backup of the complete Companion configuration right away |

The chosen view is the page of the current session (like `/showplaypi/browser/url`); after a restart the
chooser is shown again.

Reply to `/showplaypi/companion/emulators`, e.g.:

```json
{"emulators": [{"id": "JGogBBWueb55Y9MWfTphX", "name": "Stage left", "columns": 8, "rows": 4}]}
```

**Backups:** Companion's own backups (scheduled and manual) are stored in `COMPANION/BACKUP/` on the SHOWPLAYPI
drive, so they can be copied over USB, the network share or a card reader.

**Planned:** the emulator list pushed to subscribers on every change; **feedbacks** `…/companion/state` (`starting` \| `running` \|
`stopped` \| `error`) and the Companion version.

### Ontime mode (`[SYSTEM] MODE=ontime`)

Browser mode plus an Ontime server on the device (container): the kiosk browser shows the Ontime view from
`[ONTIME] VIEW` (default `timer`), and all browser commands work – any website can be shown. The Ontime
editor is at `http://<device name>.local:4001`. Ontime's own OSC input is off by default; it must not use
ShowPlayPI's port `23878`.

| Command | Arguments | Effect |
|---|---|---|
| `/showplaypi/ontime/view` | view `[options …]` | shows an Ontime view with the options of its settings panel, passed on unchanged – as one string (`"stopCycle=true&extra-info=0-Custom+data"`) or as several strings (`"stopCycle=true"` `"extra-info=0-Custom+data"`) |

Views: `timer`, `backstage`, `countdown`, `studio`, `timeline` (and Ontime's other pages such as `cuesheet`
or `op`). Example – the backstage view without cycling and with a custom data field:

```
/showplaypi/ontime/view "backstage" "stopCycle=true&extra-info=0-Custom+data"
→ http://127.0.0.1:4001/backstage/?stopCycle=true&extra-info=0-Custom+data
```

Like every page set via OSC, the view lasts until the next restart; the start view is set in
`showplaypi.ini` (`[ONTIME] VIEW=backstage?stopCycle=true`, the options after `?`). This lets the Companion
module offer every setting of Ontime's views.

### Audio player (`[AUDIO] ENABLED=yes`)

**First version implemented** (`showplaypi-audio`, two mpv players): all commands in the tables below; `list`
and `status` answer to the sender. Not yet: feedbacks for subscribers, and track durations in the file lists
before a file has played once (`null` until then).

The audio player is an **optional extra in every mode** (`[AUDIO] ENABLED=yes`); it runs next to the chosen
mode. Two sources on the SHOWPLAYPI drive:

- `AUDIO/` – **jingles**: single files, played on demand
- `AUDIO/LOOP/` – **playlists**: the folder itself is always playlist 1 and the default; its subfolders
  follow as playlists 2, 3, … in alphabetical order (one level, deeper folders are ignored), e.g.
  `AUDIO/LOOP/Admission/`, `AUDIO/LOOP/Break/`. Files play in alphabetical order.

Formats: WAV, MP3, FLAC, OGG/Opus, M4A/AAC. **Volumes are always in percent** (`0`–`100`), never in dB.
`[fade]` is an optional fade time in **milliseconds** (`i`); without it the change is immediate.
By default the audio player **only plays on command** (`…/loop/play`, `…/jingle/play`). Opt-in for a
background music player: with `[AUDIO] AUTOSTART=yes` playlist 1 starts automatically after the device has
started. Jingles never start on their own.
Start values (volumes, jingle behaviour) come from `showplaypi.ini`;
everything set via OSC lasts until the next reboot. The sound plays on all outputs at once (HDMI, the
headphone jack of the Pi 4, a USB sound card on outputs 1-2). File names are matched exactly (case-insensitive,
with or without extension), e.g. `"01_Gong"` for `01_Gong.wav`.

**Playlist**

| Command | Arguments | Effect |
|---|---|---|
| `/showplaypi/audio/loop/play` | `[fade]` | start or resume the current playlist, optionally fading in |
| `/showplaypi/audio/loop/pause` | `[fade]` | pause, optionally fading out |
| `/showplaypi/audio/loop/toggle` | `[fade]` | play/pause (one button in Companion) |
| `/showplaypi/audio/loop/stop` | `[fade]` | stop, optionally fading out; the next play starts at the beginning |
| `/showplaypi/audio/loop/next` / `previous` | – | skip within the playlist |
| `/showplaypi/audio/loop/restart` | – | play the current track from the beginning |
| `/showplaypi/audio/loop/playhead` | milliseconds | set the playhead of the current track, counted from its start |
| `/showplaypi/audio/loop/playhead/end` | milliseconds | set the playhead counted back from the end (e.g. `10000` = T-10 s) |
| `/showplaypi/audio/loop/select` | number or file name | play this track of the current playlist |
| `/showplaypi/audio/loop/playlist` | playlist name or number | switch playlist (`LOOP` = the default); keeps playing if it was playing |
| `/showplaypi/audio/loop/repeat` | `off` \| `all` \| `one` | repeat mode |
| `/showplaypi/audio/loop/shuffle` | `0` \| `1` | shuffle off/on |
| `/showplaypi/audio/loop/volume` | `0`–`100` `[fade]` | playlist volume in percent |

**Jingles**

| Command | Arguments | Effect |
|---|---|---|
| `/showplaypi/audio/jingle/play` | number or file name `[volume]` | play a jingle once; a new jingle replaces a running one |
| `/showplaypi/audio/jingle/stop` | `[fade]` | stop the current jingle |
| `/showplaypi/audio/jingle/volume` | `0`–`100` | jingle volume in percent |
| `/showplaypi/audio/jingle/mode` | `duck` \| `pause` `[percent]` | what the playlist does while a jingle plays: `duck` lowers it to `percent` of its volume (e.g. `30`; `100` = unchanged), `pause` pauses it; afterwards it continues |

**All audio**

| Command | Arguments | Effect |
|---|---|---|
| `/showplaypi/audio/volume` | `0`–`100` `[fade]` | master volume in percent |
| `/showplaypi/audio/mute` | `0` \| `1` \| `toggle` | master mute |
| `/showplaypi/audio/stopall` | `[fade]` | stop playlist and jingle (e.g. an emergency button) |
| `/showplaypi/audio/list` | – | send the file lists (below) to the requester |
| `/showplaypi/audio/status` | – | send the player state as JSON to the requester |

File list `/showplaypi/audio/files` (after the handshake, on changes and on `list`), e.g.:

```json
{
  "jingles": [
    {"number": 1, "file": "01_Opening.wav", "title": "01_Opening", "duration": 8400},
    {"number": 2, "file": "02_Applause.mp3", "title": "02_Applause", "duration": 12000}
  ],
  "playlists": [
    {"number": 1, "name": "LOOP", "default": true, "tracks": [
      {"number": 1, "file": "Lounge 01.mp3", "title": "Lounge 01", "duration": 214500}
    ]},
    {"number": 2, "name": "Admission", "default": false, "tracks": [
      {"number": 1, "file": "Walk-in.mp3", "title": "Walk-in", "duration": 187000}
    ]}
  ]
}
```

Status `/showplaypi/audio/status` (on request and as the full status after the handshake), e.g.:
`{"loop": {"state": "playing", "playlist": "LOOP", "number": 1, "file": "Lounge 01.mp3", "elapsed": 83200,
"remaining": 131300, "volume": 60, "repeat": "all", "shuffle": false}, "jingle": {"state": "stopped",
"volume": 100, "mode": "duck", "duck": 30}, "volume": 80, "mute": false}`

**Feedbacks** for subscribers (on change): `…/loop/state` (`playing` \| `paused` \| `stopped`),
`…/loop/playlist`, `…/loop/track` (number and title), `…/loop/elapsed` and `…/loop/remaining`, `…/jingle/state`,
`…/jingle/elapsed` and `…/jingle/remaining`, and all volumes and mute. Times in milliseconds; elapsed and
remaining time are sent once per second while playing and immediately on start, pause and every playhead
change.

### Further plans

- Support for OSC bundles.
