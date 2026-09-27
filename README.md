# ShowPlayPI

**Turn a Raspberry Pi into a show playout device for events, trade fairs and control rooms – web pages,
videos, Bitfocus Companion or an Ontime timer, without any Raspberry Pi knowledge.**

ShowPlayPI starts straight into what the device is meant to do: a full-screen web page (a stage timer, a
dashboard, a schedule, a sign), a looping video and slideshow player, a Companion control surface or an Ontime
timer display. You configure it with a simple Windows program or a text file – no Linux, no command line –
and control it live via OSC.

> **Status: beta.** ShowPlayPI is in active development. The current version is `1.0.0-beta.3`, with first
> versions of the video, Companion and Ontime modes and the audio player. The first stable release will be
> 1.0.0. See [known issues](#known-issues) before using it at a show, and the [roadmap](ROADMAP.md) for what
> comes next.

## Modes

One setting in `showplaypi.ini` decides what the device does – `[SYSTEM] MODE`:

| Mode | What the screen shows |
|---|---|
| `browser` (default) | a web page or a local HTML page in a full-screen browser (kiosk) |
| `video` | videos and still images from the folder `VIDEO`, full-screen, in a loop, with fades |
| `companion` | [Bitfocus Companion](https://bitfocus.io/companion) runs on the device; the screen shows its emulator chooser (touch, mouse, keyboard) |
| `ontime` | an [Ontime](https://getontime.nl) server runs on the device; the screen shows a timer view |

In `companion` and `ontime` mode the browser keeps all its functions – any web page can be shown instead,
e.g. via OSC. The **audio player** is an optional extra that can be switched on in every mode
(`[AUDIO] ENABLED=yes`). The mode changes only through the configuration and takes effect after a restart.

## Features

- **Full-screen kiosk browser** (Chromium) for websites (`http://`, `https://`) and local pages (`file://`) –
  with a watchdog that reloads the page as soon as the server is back, and an idle timeout that returns to
  the start page and can clear cookies and logins for the next visitor
- **Video and slideshow player:** plays the folder `VIDEO` in alphabetical order in an endless loop, still
  images with their own display time (`Sponsors [15sec].jpg`), subfolders as further playlists, hardware
  decoding of H.265/HEVC up to 4K60 (Pi 4 and Pi 5) and of H.264 up to 1080p60 (Pi 4)
- **Companion and Ontime on the device** – no extra computer needed; their web interfaces are announced on
  the network and appear in the Windows network view
- **Audio player:** background music with playlists and jingles on command – a jingle ducks or pauses the
  music, which continues afterwards; fades for every change
- **Sound on every output at once:** both HDMI ports, the headphone jack (Pi 4) and a USB sound card
  (outputs 1-2)
- **Works without a display** – always outputs a 1080p60 signal (configurable), so video mixers and
  projectors stay locked
- **Easy configuration:** everything is on the drive **`SHOWPLAYPI`** – reachable over USB-C, over the
  network or with the SD card in a card reader; the Windows configurator is on it
- **Live control via OSC**, e.g. from Bitfocus Companion: change pages, control the video player, choose
  Companion emulators and Ontime views, black out the picture without losing the HDMI signal
  ([OSC reference](docs/OSC.md))
- **VNC** to see exactly what is on the screen – in every mode
- Network: DHCP or static IP, device name, time zone (detected automatically from the internet
  connection), time server
- **Self-maintaining:** unique device names, automatic data hygiene (browser caches, logs, temporary files),
  deleted files on the drive are restored

## What you need

- **Raspberry Pi 5 or Raspberry Pi 4 Model B** (the Pi 5 is the main platform; the Pi 4 is still being tested
  in the beta). For the Companion mode the RAM decides how many connections are possible – every Companion
  connection is a program of its own (about 25–35 MB each): **1 GB** only for small setups (up to about 5
  connections), **2 GB** for typical events, **4 GB** recommended for large setups. When the memory runs
  low, ShowPlayPI logs a warning (`journalctl -u showplaypi-monitor`), and `/showplaypi/system` reports it
  via OSC.
- A microSD card, **16 GB or larger**
- A suitable power supply (Pi 5: 27 W USB-C, Pi 4: 15 W USB-C) – **or Power over Ethernet**: the official
  PoE HATs work on both models, **PoE+ is recommended** (a single network cable for power and data)
- A micro-HDMI to HDMI cable – use the HDMI port **next to the USB-C power socket** (see
  [known issues](#known-issues))
- A network cable if the content comes from the network or the device is controlled remotely

## Quick start

1. **Download** the latest image `ShowPlayPI-<version>.img.xz` from the
   [releases page](https://github.com/robertskiba/ShowPlayPI/releases).
2. **Write it to the SD card** with the [Raspberry Pi Imager](https://www.raspberrypi.com/software/):
   *Choose Device* → your Pi model, *Choose OS* → *Use custom* → the downloaded file,
   *Choose Storage* → your SD card.
   When the Imager asks whether to apply **OS customisation settings, choose "No"** – ShowPlayPI brings its
   own configuration, and customisation from the Imager would interfere with it.
3. **Configure** (optional, can also be done later with the configurator via USB-C, see below):
   open the SD card on your computer – a drive called `bootfs` appears – and edit `showplaypi.ini`.
   For a web page, the most important setting is the page to show:
   ```ini
   [BROWSER]
   URL=http://192.168.1.100:4001/timer/
   ```
4. **Start:** insert the card into the Pi, connect HDMI and network, then power it on.
   The first start takes a little longer, because the Pi prepares the SD card: it enlarges the system
   partition and creates the drive `SHOWPLAYPI` in the remaining space.

In browser mode without a configured URL, ShowPlayPI shows its **setup page** with the device name, IP
address and instructions.

## Configuration

All settings live in one file: **`showplaypi.ini`** on the drive **`SHOWPLAYPI`**. The drive also holds
the Windows configurator and folders for your own files:

| On the drive | Purpose |
|---|---|
| `showplaypi.ini` | the configuration |
| `ShowPlayPI-Configurator.exe` | configurator for Windows |
| `HTML` | your own web pages for the browser |
| `VIDEO` | videos and still images for the video mode; subfolders are further playlists |
| `AUDIO`, `AUDIO/LOOP` | jingles and background music for the audio player; subfolders of `LOOP` are further playlists |
| `PRESETS` | presets, e.g. the Bitfocus Companion page |
| `COMPANION/BACKUP` | Companion's backups (Companion mode only) |

Changes are applied the next time ShowPlayPI starts – a running show is never interrupted by a saved
change. **Deleting `showplaypi.ini` from the drive resets the configuration to the delivery state** at the
next start; your files in the folders are kept. The configurator, the README and the folders are restored
automatically if they are deleted.

There are three ways to reach the drive.

### 1. Via USB-C with the configurator (recommended)

Connect the Pi's **USB-C port** to a computer with a USB cable. A drive called **`SHOWPLAYPI`** appears,
containing `showplaypi.ini`, a README and **`ShowPlayPI-Configurator.exe`**.

- **Windows:** start `ShowPlayPI-Configurator.exe` from the drive. It shows all settings in a clear window,
  checks your input and saves the file on the drive. **Save and Restart** applies the settings right away.
- **Mac/Linux:** edit `showplaypi.ini` on the drive with a plain-text editor
  (a web interface for all systems is planned). On a Mac, eject the drive in Finder before unplugging the
  cable – macOS keeps changes in its own cache for a while.

After saving you can unplug the USB cable right away – ShowPlayPI writes every change to its SD card
immediately, and the configurator only reports success once the settings are stored there.

While a computer is connected, ShowPlayPI is in **USB configuration mode**: playback pauses and a status
screen shows what is going on (a computer's USB port can hardly ever power a Pi for normal operation, and
the drive belongs to the computer meanwhile). The status screen confirms when your changes are saved.
When you are done, unplug the USB cable:
- **Powered by PoE or its own power supply:** ShowPlayPI restarts right away with the new settings.
- **Powered by the computer:** it switches off with the cable – start it with its power supply or PoE.

A Pi 5 needs a USB-C or USB 3 port on the computer to start at all; old USB 2 ports are too weak.
With `[SYSTEM] USB_CONFIG_MODE=no` playback continues while a computer is connected.

### 2. Over the local network

The drive is also shared on the network (user name `admin`, password `admin`):

- **Windows:** open `\\showplaypi-xxxxxx.local\SHOWPLAYPI` in File Explorer – ShowPlayPI also appears under
  *Network*.
- **Mac:** Finder › *Go* › *Connect to Server* › `smb://showplaypi-xxxxxx.local/SHOWPLAYPI`

`showplaypi-xxxxxx` is the device name (see [device name](#device-name)). With **Save and Restart** in the
configurator, ShowPlayPI applies the settings right away. While a computer uses the drive over USB-C, the
network share pauses. It can be switched off with `[NETWORK_SHARE] ENABLED=no`.

### 3. On the SD card with any text editor

Power the Pi off and insert the SD card into a computer. Two drives appear: `SHOWPLAYPI` and `bootfs`.
Both contain `showplaypi.ini` – edit either one with a plain-text editor (Notepad, TextEdit – **not** Word);
the changed file wins at the next start and the other copy is updated. Right after flashing, before the
first start, only `bootfs` exists. Lines starting with `;` are comments; every setting is explained in the
file itself.

To use the card for something else, run **`Clear-SD-Card.cmd`** on the `bootfs` drive: after a confirmation it
removes all ShowPlayPI partitions and leaves an empty card with one partition `SDCARD` (it works only on the
ShowPlayPI card it is started from).

### Settings overview

| Section | Setting | Default | Meaning |
|---|---|---|---|
| `[SYSTEM]` | `MODE` | `browser` | Operating mode: `browser`, `video`, `companion` or `ontime` (see [modes](#modes)) |
| | `HOSTNAME` | `showplaypi` | Device name. The default `showplaypi` becomes `showplaypi-` plus the last six digits of the MAC address, e.g. `showplaypi-e84042` (see [device name](#device-name)); any other name is used as it is |
| | `TIMEZONE` | `auto` | Time zone; `auto` = detected from the internet connection at every start (the public IP address is sent to a free GeoIP service; offline the last detected one is kept, at first `Europe/Berlin`), or a name such as `Europe/London` |
| | `NTP_SERVER` | `192.53.103.108` | Time server (PTB, Germany) |
| | `USB_CONFIG_MODE` | `yes` | Configuration mode while a computer is connected via USB-C: playback pauses, and after unplugging ShowPlayPI restarts with the new settings (`no` = keep playing) |
| | `BOOT_MESSAGES` | `no` | Show the system messages instead of the startup image while booting (troubleshooting) |
| `[NETWORK]` | `MODE` | `dhcp` | `dhcp` or `static` |
| | `IP`, `NETMASK`, `GATEWAY` | – | Only for `MODE=static` |
| | `DNS1`, `DNS2` | –, `8.8.8.8` | Additional DNS servers (optional) |
| `[BROWSER]` | `URL` | – | Page to show (`http://`, `https://`, `file://`); empty = the default page of the mode (setup page, Companion emulator chooser or Ontime view) |
| | `IGNORE_CERTIFICATE_ERRORS` | `yes` | Accept self-signed HTTPS certificates |
| | `WATCHDOG_ENABLED` | `yes` | Reload the page when the server is back |
| | `WATCHDOG_INTERVAL` | `5` | Seconds between checks (2–300) |
| | `RELOAD_INTERVAL` | `0` | Reload every n seconds, `0` = off |
| | `IDLE_TIMEOUT` | `0` | Return to the start page after n seconds without touch/mouse/keyboard, `0` = off |
| | `IDLE_ACTION` | `home` | `home` (only if the visitor left the start page) or `reload` (always reset after use) |
| | `IDLE_CLEAR_SESSION` | `no` | Clear cookies, form data and logins on reset (public kiosks) |
| `[VIDEO]` | `AUTOSTART` | `yes` | Start playing after the start; `no` = black until an OSC play command |
| | `PLAYLIST` | `VIDEO` | Start playlist: `VIDEO` or the name of a subfolder |
| | `TRANSITION` | `crossfade` | `crossfade` (in preparation – fades through black for now) or `black` |
| | `FADE` | `1000` | Fade time in milliseconds, `0` = hard cut |
| | `STILL_DURATION` | `10` | Seconds per still image; a tag in the file name wins, e.g. `Sponsors [15sec].jpg` |
| | `STILL_FIT` | `fit` | `fit` (whole image, black bars) or `fill` (fill the screen, crop the edges) |
| | `VOLUME` | `100` | Volume of the videos in percent |
| `[AUDIO]` | `ENABLED` | `no` | Switch the audio player on – an optional extra in every mode |
| | `AUTOSTART` | `no` | Start the background music (`AUDIO/LOOP`) automatically after the start |
| | `VOLUME`, `LOOP_VOLUME`, `JINGLE_VOLUME` | `100`, `80`, `100` | Volumes in percent: all audio, music, jingles |
| | `JINGLE_MODE`, `DUCK_LEVEL` | `duck`, `30` | While a jingle plays the music gets quieter (`duck`, to `DUCK_LEVEL` percent) or pauses (`pause`) |
| | `REPEAT`, `SHUFFLE` | `all`, `no` | Repeat the music (`all`, `one`, `off`) and random order |
| `[ONTIME]` | `VIEW` | `timer` | Ontime view on the screen: `timer`, `backstage`, `countdown`, `studio`, `timeline`; options of the view after `?`, e.g. `backstage?stopCycle=true` |
| `[DISPLAY]` | `MODE` | `auto` | `auto` (display's preferred mode) or `fixed` |
| | `FALLBACK` | `1920x1080@60` | Output when no display is connected |
| | `RESOLUTION`, `REFRESH` | `1920x1080`, `60` | Used with `MODE=fixed` |
| `[VNC]` | `ENABLED`, `PORT` | `yes`, `5900` | Remote view |
| `[NETWORK_SHARE]` | `ENABLED` | `yes` | Share the `SHOWPLAYPI` drive on the network (user `admin`, password `admin`) |
| `[DISCOVERY]` | `UPNP` | `yes` | Announce the running web interfaces (Companion, Ontime) in the Windows network view |
| `[OSC]` | `ENABLED` | `yes` | OSC remote control on UDP port 23878 (changes last until the next restart) |

### Device name

Every ShowPlayPI has its own name: `showplaypi-` plus the last six digits of its MAC address, for example
`showplaypi-e84042`. It is fixed from the first start, so several devices never get in each other's way –
even if they are not online at the same time. On the network the device is reachable as
`showplaypi-xxxxxx.local`; the name is shown on the setup page, on the status screen and in the Windows
network view. To choose your own name, set `HOSTNAME` in `[SYSTEM]`.

## Using the modes

### Browser

Set the page in `[BROWSER] URL`. For your own HTML pages (with images, scripts, styles), put them into the
**`HTML`** folder on the `SHOWPLAYPI` drive and use for example:

```ini
URL=file:///media/showplaypi/HTML/index.html
```

Upper and lower case in the path do not matter on this drive.

### Video

Copy videos (MP4, MOV, MKV, WebM …) and still images (JPG, PNG, WebP) into the folder **`VIDEO`** and set
`MODE=video`. They play in alphabetical order in an endless loop – number them to set the order, e.g.
`010_Intro.mp4`, `020_Sponsors [15sec].jpg`, `030_Trailer.mp4`. Subfolders of `VIDEO` are further playlists,
switchable via OSC. New files are picked up while playing.

Which formats the Pi decodes in hardware:

| | H.265/HEVC | H.264 |
|---|---|---|
| **Raspberry Pi 5** | in hardware, up to 4K60 | **no hardware decoder** – in software, smooth up to 1080p30 |
| **Raspberry Pi 4** | in hardware, up to 4K60 | in hardware, up to 1080p60 |

**Best format: H.265/HEVC** – it plays in hardware on both models (on the Pi 5 measured up to 4K60 without
dropped frames). Sound plays on all outputs at once (see [features](#features)).

### Companion

Set `MODE=companion`. Companion runs on the device; set it up in a browser at
`http://showplaypi-xxxxxx.local:8000` (connections, buttons, emulators). The screen shows Companion's
emulator chooser – pick an emulator by touch or mouse, or via OSC (`/showplaypi/companion/emulator`).
USB control surfaces such as the Stream Deck can be plugged into the Pi. Companion's backups are stored in
`COMPANION/BACKUP` on the drive.

### Audio

Copy jingles (WAV, MP3, FLAC, OGG, M4A …) into the folder **`AUDIO`** and background music into
**`AUDIO/LOOP`** (subfolders of `LOOP` are further playlists) and set `[AUDIO] ENABLED=yes` – the audio player
then runs next to the chosen mode. Everything is controlled via OSC, e.g.
`/showplaypi/audio/loop/play 2000` (fade in over 2 s) or `/showplaypi/audio/jingle/play "01_Gong"`; with
`[AUDIO] AUTOSTART=yes` the music starts by itself.

### Ontime

Set `MODE=ontime`. Ontime runs on the device; its editor is at `http://showplaypi-xxxxxx.local:4001`. The
screen shows the view from `[ONTIME] VIEW` (default `timer`); other views and their options can be chosen
via OSC (`/showplaypi/ontime/view`).

## Remote access

| What | How | Default login |
|---|---|---|
| **OSC** | UDP port 23878, commands such as `/showplaypi/browser/url`, `/showplaypi/blackout`, `/showplaypi/video/…`, `/showplaypi/system` (load, memory, temperature) – see [docs/OSC.md](docs/OSC.md) | – |
| **VNC** | any VNC viewer, `showplaypi-xxxxxx.local:5900` | password `admin` |
| **Companion** (mode `companion`) | `http://showplaypi-xxxxxx.local:8000` | – |
| **Ontime** (mode `ontime`) | `http://showplaypi-xxxxxx.local:4001` | – |
| **SSH** | `ssh admin@showplaypi-xxxxxx.local` | user `admin`, password `admin` |
| **Network share** | `\\showplaypi-xxxxxx.local\SHOWPLAYPI` (Windows), `smb://showplaypi-xxxxxx.local/SHOWPLAYPI` (Mac) | user `admin`, password `admin` |

Running web interfaces (Companion, Ontime) are also announced via UPnP: in Windows they appear under
**Network** (e.g. "showplaypi-e84042 – Companion") and open with a double-click.

A ready-made **Bitfocus Companion page** (`ShowPlayPI Companion Demo.companionconfig`) is in the `PRESETS`
folder of the `SHOWPLAYPI` drive – import it into Companion and set the IP of your Pi.

If the `.local` name does not work on your network, use the IP address shown on the setup page.

## Security

ShowPlayPI is built for **isolated event networks** and is deliberately easy to use: the default
passwords are `admin`, and OSC has no authentication. **Do not connect it unchanged to a company network or
the internet.** VNC, the network share, the UPnP announcement and OSC can each be switched off in
`showplaypi.ini`; further options to lock everything down (own passwords, OSC password, disabling SSH,
firewall) are planned – see the [roadmap](ROADMAP.md).

With `TIMEZONE=auto` the device asks a free GeoIP service for its time zone at every start (the public IP
address is sent to it); set a fixed time zone to avoid this.

## Known issues

In this beta:

- Only the HDMI port **next to the USB-C socket** is fully supported; both outputs with the same picture
  are planned for 1.1.
- The video, Companion and Ontime modes and the audio player are first versions: crossfades between videos
  fade through black for now, and everything is tested on the Pi 5 so far, not yet on the Pi 4.
- Companion on a 1 GB Pi: with about 15 connections the memory is nearly used up, with 30 connections the
  device stalls. Use a Pi with 2 or 4 GB for larger Companion setups.
- Configuration via USB-C depends on the power the computer's USB port delivers; the Pi 5 needs a USB-C
  or USB 3 port.

## Troubleshooting

| Problem | Solution |
|---|---|
| The setup page appears instead of my page | Check `URL` in `[BROWSER]` – it must start with `http://`, `https://` or `file://`. |
| Companion or Ontime mode shows another page | An own `URL` in `[BROWSER]` replaces their view – leave it empty. |
| Videos stutter | Convert them to H.265/HEVC; on a Pi 5, H.264 is only smooth up to 1080p30 (the Pi 4 decodes H.264 in hardware up to 1080p60). |
| Not reachable after setting a static IP | Power off, put the SD card into a computer, fix `[NETWORK]` or set `MODE=dhcp`. |
| The page does not come back after a server outage | Make sure `WATCHDOG_ENABLED=yes`. |
| No picture on the display | Use the HDMI port next to USB-C; try `[DISPLAY] MODE=fixed` with a resolution your display supports. |
| The `.local` name is not found | Use the IP address from the setup page; some networks block `.local` names. |

More help: [support@konftools.com](mailto:support@konftools.com)

## More

- [Changelog](CHANGELOG.md) · [Roadmap](ROADMAP.md) · [OSC reference](docs/OSC.md)
- [Development: build and test ShowPlayPI yourself](docs/DEVELOPMENT.md)
- License: [MIT](LICENSE); the image also contains third-party software under its own licenses, including
  Bitfocus Companion and Ontime – see [THIRD-PARTY.md](THIRD-PARTY.md). ShowPlayPI is not affiliated with
  or endorsed by the Bitfocus Companion or Ontime projects.

---

ShowPlayPI by Robert Skiba · https://konftools.com · support@konftools.com
