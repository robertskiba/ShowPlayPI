# Roadmap

As of 2026-09-23. Structured by releases: each release has a goal, its work items and a
**definition of done**. Security options are attached to the release that introduces the interface
they protect.

## Target picture

A platform for Raspberry Pi 4B and Pi 5 with **separate modes**. Exactly one of them runs at any time:

| Mode | Function |
|---|---|
| `browser` | Full-screen browser for websites and local HTML pages (kiosk) |
| `video` | Full-screen video and still-image player: HEVC/H.264 videos and JPG/PNG/WebP images (also as a pure slideshow) from a folder (playlist) on the media partition, alphabetical, looping, crossfades |
| `ontime` | Browser mode plus an [Ontime](https://getontime.nl) server in the background (container, Podman); the browser shows a timer view by default |
| `companion` | Browser mode plus Bitfocus Companion in the background (native ARM64 build); the browser shows the Companion emulator chooser (touch, mouse, keyboard) |

In `ontime` and `companion` mode the browser can be switched off (`[DISPLAY] BROWSER=no`): the server runs
without X11/Chromium and the screen only shows a text console with device name, IP address and the address of
the Ontime/Companion web interface.

More modes should be easy to add later.

## Ground rules

- **Usability first:** anyone without Raspberry Pi knowledge must be able to use the image.
  Configuration happens through the Windows configurator, the web interface or the INI file.
- **Open by default, secure by choice:** out of the box everything is simple and open (isolated event
  networks). Every interface gets an optional protection that can be enabled in the INI/configurator.
- The **mode** is set **only** through the INI file, **never through OSC**.
- **OSC in every mode** for live operation; `docs/OSC.md` is the authoritative reference. Commands of a mode
  or service that is not active are ignored.
- **Both HDMI outputs** always carry a signal and show the same picture.
- **Updates** happen only at boot and only with internet; they touch ShowPlayPI scripts and packages, never the whole operating system, and can be
  rolled back.

## Overview

| Release | Goal | Depends on |
|---|---|---|
| Groundwork ✅ | Repository, build, deploy, review (no release) | – |
| **1.0** | Browser mode stable on Pi 4B and Pi 5 – **first public release**, preceded by betas `1.0.0-beta.N` | Groundwork |
| **2.0** | Platform: modes, new INI, partitions, OSC service, updater | 1.0 |
| **2.1** | Video & stills mode + web interface (configuration and media upload) | 2.0 |
| **2.2** | Ontime mode | 2.0 |
| **2.3** | Companion mode | 2.0 |
| **2.4** | Audio player: background playlist and jingles (optional service) | 2.0 |
| **3.0** | Companion module, distribution | 2.1–2.4 |

---

## Groundwork ✅ (not a release)
- [x] `deploy.sh` (development on a running Pi), `build/build.sh` (reproducible image), `build/compare.sh`
- [x] Repository on GitHub, all content in English
- [x] Virtual USB configuration drive created automatically if missing
- [x] Code review of all scripts (2026-09-23); findings fixed, hardware questions moved to 1.0
- [x] OSC commands documented (`docs/OSC.md`)

## 1.0 – Browser mode stable (first public release)

Iterated as betas (`1.0.0-beta.1`, `-beta.2`, …) until the definition of done is met.

Goal: the existing browser function runs reliably on both Pi models and is ready to be handed to users.

**Hardware and display**
- [ ] Verify the build image on Pi 4B and Pi 5 (boot, first-boot resize, SSH, VNC, OSC, watchdog)
- [ ] **Both HDMI outputs** always carry a signal (at least 1080p60 headless, configurable) and are
      **mirrored**; with different displays a common resolution, if in doubt the configured one or 1080p60
- [ ] **Screen rotation** for portrait signage and kiosks: `[DISPLAY] ROTATION=0|90|180|270`, also in the
      configurator; touch input rotated accordingly; applies to both HDMI outputs
- [x] Pi 5: Xorg failed to start (separate display/3D devices) – fixed with an Xorg OutputClass for vc4
      (tested on a Pi 5 via PoE, 2026-09-25)
- [ ] Pi 5 specifics: headless resolution, USB gadget over USB-C (a PC USB port cannot power a Pi 5 –
      test with PoE + data-only USB-C), which HDMI port is detected as connected
- [ ] Booting without network does not delay the browser (currently waits for `network-online.target`,
      possibly ~60 s)
- [ ] VNC performance: check whether the x11vnc options `-sb 0 -nonap -nowait_bog` are needed
- [ ] Power only via USB-C from a PC: check behaviour (gadget reports 250 mA). Works on the Pi 4; the Pi 5
      did not start at all from a PC USB port (red LED – the bootloader never ran, no software can fix that)
- [x] **USB configuration mode** (`USB_CONFIG_MODE=yes`, 2026-09-25): whenever a computer is connected via
      USB-C, ShowPlayPI is a drive, not a player – kiosk, VNC and watchdog stop, a status screen is shown, CPU
      in power-save mode, Wi-Fi/Bluetooth off. Decided instead of detecting a weak supply: a PC port can hardly
      ever power a Pi, the Pi 4 does not report its supply current, and an under-voltage is only noticed once
      it has happened. After unplugging, ShowPlayPI restarts with the new settings (PoE or power supply).
      - [ ] Test on the Pi 4B.
- [x] USB configuration drive works on the Pi 5 (gadget controller `1000480000.usb`, drive created
      automatically on first boot; tested via PoE, 2026-09-25)
- [ ] **Power over Ethernet:** official PoE HATs on Pi 4B and Pi 5 (PoE+ recommended) – verify stable
      operation under load (Chromium, both HDMI outputs) and HAT fan control

**Kiosk behaviour**
- [x] **Idle timeout – return to the start page** (essential for kiosks of any kind) – implemented
      (`showplaypi-idle`), to be verified on touch hardware:
      `[BROWSER] IDLE_TIMEOUT=<seconds>` (`0` = off), also in the configurator.
  - Idle = no touch, mouse or keyboard input (measured at the X server).
  - Only acts after real user input and, with `IDLE_ACTION=home`, only if the page shown differs from the
    start page – display-only screens are never reset (current URL read locally from Chromium).
    Simulated key presses of the watchdog are not counted as input.
  - `IDLE_ACTION=home|reload`: `reload` also resets web apps whose URL does not change while being used.
  - `IDLE_CLEAR_SESSION=yes|no`: clear cookies, form data and logins on reset (public kiosks, privacy).
  - The idle timeout returns to the **session start page**: a page set via `/showplaypi/browser/url` becomes the
    start page for the running session until the next reboot; `/showplaypi/browser/home` discards it and returns
    to the start page from the INI.
  - New OSC command `/showplaypi/browser/idle <milliseconds>` (`0` = off): enables, changes or disables the idle
    timeout for the running session.

- [ ] **URL allow list** so visitors cannot follow a link out of the kiosk content into the internet:
      `[BROWSER] ALLOWED_URLS=` (domains/URL patterns, empty = everything allowed), also in the configurator.
      Implemented through Chromium policies (URL allow/block list); the session start page is always allowed;
      optionally also disable the context menu (right click / long press).
- [x] **Automatic data hygiene** (important – devices are far too often passed on without a reset) –
      implemented (`showplaypi-data-hygiene`), tested on a Pi 5 (2026-09-25):
  - Browser caches, history and temporary files are deleted **at least every 14 days**: at start-up when the
    last cleanup is older than that; on devices running for weeks without a restart, the HTTP cache is
    cleared through the browser's debugging interface (no visible interruption), the rest at the next start.
  - **Cookies and site data** (logins, local storage, saved form data) are deleted as soon as the
    **start page URL in the configuration changes** – a new customer or event starts with a clean browser.
    Not on URL changes via OSC during a show (they would log out pages that are switched on purpose).
  - Journal logs are size-limited so they never fill the Linux partition.

**OSC and discovery**
- [ ] **Bonjour/mDNS announcement** so controllers find devices automatically (Companion modules can
      discover devices via Bonjour): advertise the OSC service (`_osc._udp`, port 23878) and a ShowPlayPI
      service with TXT records (name, version, mode) via Avahi, which already runs on the device.
- [x] **UTF-8 URLs with umlauts and other non-ASCII characters** work via OSC and in the INI
      (`showplaypi_url.py`, 32 automated test cases):
  - Decode OSC strings as UTF-8, fall back to Latin-1 for older senders instead of rejecting the command.
  - Normalise every URL before it is stored or used: host name to IDNA/punycode
    (`müller.de` → `xn--mller-kva.de`), non-ASCII characters in path and query percent-encoded
    (`/über` → `/%C3%BCber`), already encoded URLs not encoded twice. Everything downstream (Chromium,
    watchdog/curl, idle service) then only sees ASCII.
  - Tests: umlaut domain, umlaut path, spaces, already encoded URLs, `file://` paths with umlauts.

**Configuration**
- [ ] USB configuration finished: import on start, sync boot ↔ USB ↔ active, fall back to the last
      working INI, FAT repair (basics exist, needs testing and completion)
- [ ] Version number visible in INI, setup page and configurator
- [ ] Setup/status page: IP, hostname, URL, display mode, watchdog/OSC/VNC status
- [ ] Network recovery: if a static IP does not work, the device stays reachable (e.g. additional
      link-local address)

**Release**
- [x] `LICENSE` (MIT)
- [x] `CHANGELOG.md`, `THIRD-PARTY.md`
- [x] Build writes a package manifest (`dpkg-query -W`) next to every image – documents exactly which
      third-party versions a release contains (source-code obligations)
- [x] README for users (flashing, first steps, configurator); developer notes in `docs/DEVELOPMENT.md`
- [ ] Release on GitHub with image, checksum and configurator EXE; make the repository public (private until then)
- [x] Build writes the Raspberry Pi Imager list (`*.rpi-imager.json`) next to every image
- [ ] Publish the Imager list at a permanent URL, test it with `rpi-imager --repo <url>`, then apply for the
      official Imager list (form linked at the end of the Imager's `doc/schema-notes.md`)

**Definition of done:** a user flashes the image with Raspberry Pi Imager, configures it with the
configurator via USB-C (or a text editor on the SD card), and the browser runs on Pi 4B and Pi 5 – with and without a display,
with and without network – on both HDMI outputs.

## 2.0 – Platform

Goal: the internal structure for several modes, without new modes yet. Browser mode keeps working.

- [x] Mode framework – implemented early, in 1.0.0-beta.3: `[SYSTEM] MODE=browser|video|ontime|companion`
      in the INI (configurator: System tab), read by `showplaypi-mode`; every unit decides with an
      `ExecCondition` whether it runs in the active mode (simpler than one systemd target per mode).
      `ontime` and `companion` start only the browser part until their releases
- [x] New INI structure: `[SYSTEM] MODE=…`, one section per mode (`[VIDEO]` added in beta.3)
- [x] **New partition layout** – implemented early, in 1.0.0-beta.3 (tested on a Pi 5, 2026-09-25):
  - **Boot partition** (FAT, 512 MB as in Raspberry Pi OS). Hiding it from computers is not possible:
    Windows mounts every FAT partition on removable media whatever its MBR type (tested with `0xef` and
    `0x1c`), and the Pi 5 bootloader refuses `0x1c`. Instead its system files are hidden and it carries
    only `showplaypi.ini`, `README.txt` and `version.txt`.
  - **Linux partition** (ext4): **12 GiB** (system, Companion, container images, room for updates).
  - **Media partition "SHOWPLAYPI"** (**exFAT**, no 4 GB file limit, read/write on Windows and macOS):
    the rest of the card, created on the first start (`showplaypi-media`, takes seconds – nothing is
    moved). **Designed for 16 GB cards:** it gets at least 3 GiB – on small cards the Linux partition
    shrinks for it (down to 10.5 GiB), because "16 GB" cards differ in real size (about 14.4–14.9 GiB).
    Contents: `showplaypi.ini`, configurator, README, `HTML/`, `VIDEO/`, `AUDIO/`, `AUDIO/LOOP/`,
    `PRESETS/`.
  - **Three copies of `showplaypi.ini`:** boot partition (edit right after flashing), media partition
    (USB, network, card reader) and the active configuration on the Linux partition. At every start the
    copy changed since the last start wins (the media partition if both changed) and the others follow.
  - The **USB configuration drive is the media partition itself**: when a computer connects, ShowPlayPI
    unmounts it and offers it over USB-C; after ejecting or unplugging it is mounted again.
    Everything the computer writes is on the SD card within about a second.
- [x] **Network share** of the media partition (Samba, `admin`/`admin`, `[NETWORK_SHARE] ENABLED`), shown in
      the Windows network view (WS-Discovery via wsdd2) and the macOS Finder (Bonjour); pauses while the
      drive is used over USB-C. "Save and Restart" in the configurator applies changes right away.
- [ ] Later with the web interface (2.1): additionally announce the device via **UPnP** so it appears under
      *Other devices* in Windows with the ShowPlayPI logo; a double click opens the web interface (the entry
      under *Computers* keeps opening the share).
- [x] **Self-healing at every start** – the device always stays operational, if need be in its delivery
      state. The last working configuration is kept on the Linux partition, which users never see;
      the media partition is only the place to edit it.
  - [x] Configurator, README and presets are replaced if missing or changed (protects against manipulation).
  - [x] Missing folders are re-created empty.
  - [x] **Deleted `showplaypi.ini` = factory reset:** the default configuration is created and applied
    (documented as the way to restore the delivery state). Media files are kept.
  - [x] Invalid or damaged `showplaypi.ini`: the device runs with the last working configuration.
    - [ ] Show a note on the setup page.
  - [x] Media partition without file system: formatted again (nothing to lose).
  - [x] Media partition with a foreign file system (e.g. reformatted as NTFS): not touched, as it may hold
    data; the device runs with the last working configuration.
    - [ ] Show a warning on the setup page.
- [ ] **Full factory reset** (`[SYSTEM] FACTORY_RESET=yes`, set by a button in the configurator with a clear
      warning and confirmation, or by hand in the INI; never via OSC). On the next start, before anything
      else runs:
  - the media partition is formatted and filled with the defaults again (configurator, README, empty
    folders) – **all media files are deleted**
  - the configuration is reset to the delivery state (which also removes the `FACTORY_RESET` flag, so it
    runs only once)
  - runtime data is removed: browser profile (cookies, logins), automatically chosen hostname,
    synchronisation state, network profiles; new SSH host keys are generated
  - then the device restarts once and comes up as on the first start after flashing
  - For rental devices and before selling a device. Difference to deleting `showplaypi.ini`: that only
    resets the configuration and keeps the media files.
- [ ] Shared OSC service for all modes: feedback subscription with handshake (`/showplaypi/subscribe`,
      `/showplaypi/hello`), `/showplaypi/status`, `/showplaypi/identify` (device name and IP on the screen,
      to tell displays apart), `/showplaypi/system` (CPU, RAM, temperature, under-voltage, free space on
      request), `/showplaypi/reboot "reboot"` (emergency restart), file lists as JSON; commands of inactive modes are ignored (draft in
      `docs/OSC.md`)
- [ ] **Auto-update at boot only** (`[SYSTEM] AUTO_UPDATE=yes|no`, default `yes`):
  - Only while booting, never during operation – a running show is never interrupted.
  - Short internet check (a few seconds); without internet the device boots normally without delay
    (the usual case on isolated event networks).
  - Only **stable releases** (tags), never the development state; an optional test channel for testers.
  - Installed before the mode starts, with an "Updating ShowPlayPI…" screen.
  - **Health check** after the update (browser/OSC/services up); on failure automatic **rollback** to the
    previous version.
  - Updates ShowPlayPI files and packages only, never the whole operating system.
  - Manual update via SSH (`showplaypi-update`) for devices without internet at boot.
  - Requires the repository (or at least its releases) to be public – it is private until the 1.0 release.
- [ ] **Windows configurator 2.0 as a wizard:** goes through all settings step by step instead of tabs, and
      only asks what matters for the chosen mode
  - The mode is chosen first with large picture buttons, one per mode (browser, video, Companion, Ontime, …)
  - The **audio player** is a separate step: "Enable the audio player?" – optional in every mode, its
    settings (background playlist, jingles) only follow when enabled
  - Then the mode's settings, network, display, remote access and security (own passwords, lockable
    interfaces), and a summary page before saving ("Save" / "Save and Restart")
  - Experienced users can jump to any step directly; the INI stays the single source of all settings
- [ ] **Background services** next to the mode: optional services that run with any mode and never use
      the screen, enabled individually in a `[SERVICES]` section of the INI
- [ ] First background service: **NTP time server** for the show network. Serves time only while the Pi
      itself is synchronised (the Pi 4 has no real-time clock; the Pi 5 has one, but it needs a backup
      battery) – never hands out a wrong time.
- [ ] Background service: **HDMI-CEC display control** via OSC – the complete, universal set and nothing
      more: power on/off (standby), volume up/down, mute, input/source selection; for both HDMI outputs.
      Feedback of the display's power state where the display reports it. Many trade-fair TVs switch on by
      themselves – CEC plus OSC adds control from Companion (e.g. all displays off in the evening).
- [ ] Background service: **GPIO inputs and outputs (GPI/GPO)** via OSC: inputs (buttons, contact
      closures) send OSC messages and feedbacks to subscribers, outputs (relays, lamps) are switched via
      OSC and report their state; pins, direction, debounce and names configured in the INI.
      Check compatibility with the PoE HATs, which cover the GPIO header.
- [ ] **Thumbnail on request via OSC:** a small preview image of what is currently on screen, sent to the
      requesting subscriber (e.g. for a Companion button). Only captured on request, small size, rate
      limited – no permanent load on the device.

**Security options introduced here**
- [ ] OSC password (`/showplaypi/auth <password>`, then accepted from that IP for a limited time;
      Companion module does it automatically) and optional IP allow list; this also protects
      `/showplaypi/reboot`.
      Documented honestly: OSC is unencrypted – protects against casual takeover, not against sniffing.
- [ ] Own passwords for login and VNC; passwords entered in the INI are applied on boot and then removed
      from the file
- [ ] SSH can be disabled or restricted to keys; `sudo` with password; USB configuration drive can be
      disabled; firewall (nftables) with only the needed ports

**Definition of done:** switching `MODE` in the INI changes the running mode after a reboot; browser mode
behaves exactly as in 1.0; a device updates itself from the stable channel and can roll back.

## 2.1 – Video & stills mode + web interface

**First version of the player in 1.0.0-beta.3** (`showplaypi-video`, mpv full-screen in the X session, so
VNC and the display settings work as in browser mode; runs on the Pi 5, 1080p H.264 in software at low CPU
load): autostart, alphabetical loop, playlists from subfolders, stills with
duration tag, fit/fill, EXIF rotation, fades through black, all OSC commands of `docs/OSC.md` with `list` and
`status` replies. Still open: crossfades, feedbacks, both HDMI outputs, audio, Pi 4, 4K and HEVC.

- [ ] Player (mpv, hardware decoding) for **videos and still images** (JPG, PNG, WebP) in one playlist –
      mixed, or only images as a slideshow – from the `VIDEO` folder, alphabetically in a loop
- [ ] **Transitions:** crossfade by default (`[VIDEO] TRANSITION=crossfade|black`); stop and the end of a
      playlist played once always fade to black
- [ ] **Still images:** always scaled (up or down, never distorted) to the full height or full width, whichever
      is reached first, black bars elsewhere (`[VIDEO] STILL_FIT=fit`, default; `fill` = fill and crop);
      rotated according to their EXIF orientation. HEIC (iPhone originals) is not supported – the documentation
      recommends exporting as JPG
- [ ] **Still duration:** default in the INI (e.g. `[VIDEO] STILL_DURATION=10`); per file overridable with a
      tag in the file name, e.g. `020_Sponsors [15sec].jpg` (also `[15s]`)
- [ ] **Autostart:** playlist 1 (`VIDEO/`) starts automatically after boot, looping alphabetically
      (`[VIDEO] AUTOSTART=yes` by default; `no` = wait black for a command)
- [ ] **Playlists as subfolders** of the media folder (e.g. `morning/`, `noon/`): default playlist in the
      INI, switchable via OSC for the session (`/showplaypi/video/playlist <folder>`) – time-based
      switching is done from Companion via OSC triggers
- [ ] Both HDMI outputs mirrored in video mode too (the player runs in the X session, like the browser)
- [x] Note for users (README, drive README, INI): Pi 5 has no H.264 hardware decoder – recommend HEVC.
      Measured on the Pi 5 (1 GB, 2026-09-25): 1080p60 HEVC with hardware decoding 0 dropped frames at low
      CPU load; 1080p60 H.264 in software drops some frames in demanding scenes even with `profile=fast`.
      4K60 HEVC (output 1080p): 0 dropped frames with `profile=fast`, about 20 % of one core – the same with
      and without X, so the player stays in the X session (VNC for free). Not yet measured: 4K output mode
- [x] Sound on all outputs at once (PipeWire combine sink: both HDMI, jack, USB sound card on outputs 1-2;
      rtkit gives the audio threads real-time priority)
- [ ] Audio test with a USB sound card with more than two outputs, and on the Pi 4 headphone jack
- [ ] **Detect files that will not play smoothly:** when reading the folder, check codec, resolution and
      frame rate against the hardware (e.g. Pi 5: H.264 above 1080p30, codecs without hardware decoding)
      and flag them – in the log, in the OSC file list (e.g. `"playback": "may-stutter"`) and later in the
      web interface. The file still plays; nothing is converted on the device
- [ ] **HandBrake preset "ShowPlayPI HEVC"** in `PRESETS/` on the drive: converts videos into the recommended
      format on the computer (free for Windows and Mac, uses the computer's graphics card – much faster
      than the Pi 5, which has no hardware encoder: 1080p60 to HEVC `ultrafast` ran at about 0.3× real time,
      measured 2026-09-25). README and drive README explain the one-time import
- [ ] **OSC** under `/showplaypi/video/…` (drafted in `docs/OSC.md`): play/pause/toggle/stop with fades,
      next/previous, select, **cue** (prepare an entry, start it without delay), **playhead** from the start or
      counted back from the end (e.g. T-10 s), playlist switching, repeat
      (default: loop in alphabetical order; always fades to black at the end), fade time, still duration,
      volume, file lists and status as JSON, feedbacks with elapsed and remaining time
- [ ] **Blackout always fades** (all modes): default fade time in the INI, per command in milliseconds
- [ ] **Web interface** at `http://showplaypi.local`, via the regular network **and over USB-C**
      (USB gadget additionally offers a network connection): same settings as the Windows configurator,
      plus media upload/delete/order. This is also the configurator for Mac, iPad and phones – no install,
      no Gatekeeper warning.
- [ ] Security: optional password for the web interface
- [ ] Browser mode: bundled **HLS player page** for live streams (Chromium cannot play `.m3u8` natively),
      e.g. `URL=file:///usr/share/showplaypi/hls.html?src=https://…`

**Definition of done:** a user copies videos and images onto the media partition (card reader or web
upload), sets `MODE=video` and the playlist loops on both outputs with fades; a Companion button switches
to another subfolder.

## 2.2 – Ontime mode

**First version in 1.0.0-beta.3** (tested on the Pi 5, 2026-09-25): Ontime 4 in a Podman container
(`showplaypi-ontime.service`, host network, data in `/home/admin/ontime`, time zone from the device), image
bundled with the ShowPlayPI image and loaded on the first start; the browser shows `[ONTIME] VIEW` (with
options after `?`); OSC `/showplaypi/ontime/view <view> [options]` passes every view option on. About 95 MB
RAM (idle).

- [ ] Ontime updated at boot together with ShowPlayPI (same `AUTO_UPDATE` rules); pinned to a major version
      (tag `v4`), previous image kept for rollback
- [ ] **Bundled with the image:** the Ontime container image is included in every ShowPlayPI release, so the
      mode works offline right away; loaded on the first start of the mode ("Preparing Ontime…").
      License: GPL-3.0 – list in `THIRD-PARTY.md`, license text included, source covered by the written offer.
- [ ] **Browser mode plus Ontime in the background:** the kiosk browser (with all browser OSC commands) shows
      an Ontime timer view by default (view selectable in the INI; an own `URL` wins)
- [ ] **Browser switchable off** (`[DISPLAY] BROWSER=no`): only the server runs, the screen shows a text
      console with device name, IP address and the Ontime address
- [ ] Performance: Ontime with a browser is known to run well on a Pi 4B (the maintainer's own earlier
      image) – only confirm with the ShowPlayPI build on Pi 4B and Pi 5
- [ ] OSC/feedback forwarding where useful (Ontime has its own OSC/HTTP API)
- [ ] Security: Ontime's own access options exposed in the INI

## 2.3 – Companion mode

**First version in 1.0.0-beta.3** (tested on the Pi 5, 2026-09-25): Companion 5 as the official ARM64 build in
`/opt/companion` (`showplaypi-companion.service`, config in `/home/admin/companion`), bundled with the image;
the browser always starts with the emulator chooser; OSC `emulators` (list as JSON for a dropdown),
`emulator <id|name>`, `tablet`, `restart`; Companion's own udev rules for USB surfaces are installed
automatically (`COMPANION_SYNC_UDEV_RULES_COMMAND`). About 280 MB RAM (idle, no connections) – with Chromium
about 350 MB remain free on the 1 GB Pi 5.

- [ ] **Updates:** download the newest build within the major version (5.x) from Bitfocus' package API in
      the background, switch at the next start, back up the configuration before, check that Companion comes
      up, roll back to the previous version otherwise; major versions only after being enabled
- [ ] Test USB surfaces (Stream Deck etc.) on the device
- [ ] **Bundled with the image:** the Companion container image is included in every ShowPlayPI release, so
      the mode works offline right away; loaded on the first start of the mode ("Preparing Companion…").
      License: MIT (core; modules have their own, mostly MIT licenses) – notices in `THIRD-PARTY.md`.
      Names are used descriptively only ("includes Bitfocus Companion"), no impression of an official product.
- [x] **Browser mode plus Companion in the background:** the kiosk browser (with all browser OSC commands)
      shows the Companion emulator chooser – touch, mouse and keyboard; an own `URL` wins
- [ ] **Browser switchable off** (`[DISPLAY] BROWSER=no`): only Companion runs, the screen shows a text
      console with device name, IP address and the Companion address
- [ ] **Measurement on Pi 4B and Pi 5** before deciding the details: RAM and CPU load of Companion, Ontime and
      Chromium (emulator page) – idle, with many buttons and connections, and during start-up; per RAM size
      (Pi 4B 2/4/8 GB, Pi 5 1/2/4/8 GB – the Pi 5 test device has 1 GB). Result: recommended minimum RAM
      and whether `BROWSER=no` is needed
- [ ] **OSC** under `/showplaypi/companion/…` (drafted in `docs/OSC.md`): emulator selection page or a
      specific emulator by ID, tablet view (optionally certain pages in a grid of columns × rows buttons), restart,
      backup of the configuration
      to the SHOWPLAYPI drive; button presses go directly to Companion's own OSC/HTTP interfaces
- [x] ~~Start view in the INI~~ – decided 2026-09-25: always the emulator chooser; an emulator is chosen there
      or via OSC (list for the module's dropdown)
- [ ] **Backups on the SHOWPLAYPI drive:** Companion's own backups are redirected to `COMPANION/BACKUP/` by a
      link in the container (no Companion configuration change); the folder is created in Companion mode
      only. While a computer has the drive over USB, the USB configuration mode also pauses Companion
      (its backups), since the drive is not mounted on the device meanwhile
- [ ] Security: Companion's own admin password exposed in the INI

## 2.4 – Audio player: background playlist and jingles (optional background service)
- [ ] Optional background service (`[AUDIO] ENABLED=yes|no`), runs e.g. together with the browser mode –
      not together with the video mode (audio conflict)
- [ ] **Folders on the SHOWPLAYPI drive:**
  - `AUDIO/` – **jingles**: single files played on demand (e.g. from a Companion button)
  - `AUDIO/LOOP/` – **playlists**: the folder itself is the default playlist (played by default), each
    subfolder – one level deep – is another playlist (e.g. admission, break music); alphabetical order
- [ ] **Formats:** WAV, MP3, FLAC, OGG/Opus, M4A/AAC (all played by mpv)
- [ ] **Fade in and fade out** for play, pause, stop and volume changes (optional fade time in seconds)
- [ ] **Jingle over playlist:** while a jingle plays, the playlist is ducked to a percentage of its volume or
      paused (`JINGLE_MODE=duck|pause`, `DUCK_LEVEL` in percent), and continues automatically afterwards;
      switchable per session via OSC. **Volumes are always in percent**, never in dB.
- [ ] **Autostart opt-in:** by default the audio player only plays on command (OSC); with
      `[AUDIO] AUTOSTART=yes` playlist 1 starts after boot (background music player). Jingles never start on
      their own.
- [ ] INI settings: output (`OUTPUT=auto|hdmi|analog|usb`), start volumes, shuffle, repeat, jingle mode;
      also in the configurator
- [ ] Outputs: HDMI audio (Pi 4B and Pi 5), 3.5 mm jack (Pi 4B only – the Pi 5 has none), class-compliant
      USB audio adapters (analog output on the Pi 5). DAC HATs are not supported (they conflict with the
      recommended PoE HAT).
- [ ] **OSC** under `/showplaypi/audio/…` (session-only, ignored while the audio player is disabled) – the
      complete command set is drafted in `docs/OSC.md`: playlist and playlist switching, jingles, fades,
      jingle mode, master volume and mute, stop all, file lists and status as JSON, feedbacks for
      subscribers (current track, elapsed and remaining time, playhead, states, volumes)
- [ ] File lists as JSON arrays, sent after the handshake, on every change on the drive and on request
- [ ] Upload and manage audio files in the web interface (together with the media upload, release 2.1)

## 3.0 – Companion module and distribution
- [ ] Companion module built against `docs/OSC.md` (actions and feedbacks for all modes)
- [ ] Download page (konftools.com) with image, configurator, documentation, version history
- [ ] Download statistics: small script that regularly records the GitHub release download counts
      (GitHub itself shows no history and keeps traffic data for only 14 days)
- [ ] **Anonymous usage statistics** – how widely and how the image is used in practice (opt-out):
  - The device calls a small PHP script on konftools.com: once on the first start after flashing
    (`install`) and once a week (`weekly`, number per week ≈ active devices). Content: version, model
    (Pi 4B/Pi 5) and mode only.
  - **Never sent:** device ID, serial or MAC address, hostname, URLs or content, configuration details.
  - **Server:** the country is derived from the IP address at the moment of the request (local GeoIP
    database, no third-party lookup); MySQL stores only date, event, version, model, mode and country.
    **The IP address is never stored** – access logging is disabled for this address on the web server.
  - Without internet (usual on event networks) nothing happens: one attempt in the background with a short
    timeout, no delay, no retries. Numbers are therefore a lower bound.
  - **On by default, can be switched off:** `[SYSTEM] ANONYMOUS_STATS=yes|no`, also in the configurator;
    a short, honest privacy section in the README and on konftools.com (what is sent, where to, how to
    switch it off). Have the wording checked by someone experienced in data protection before release.
  - Later option: count the update check of the auto-updater (2.0) instead of a separate request.
- [ ] Signed Windows EXE / small installer

---

## Open decisions

| Topic | Question | Needed for |
|---|---|---|
| Third-party licenses | The image bundles Raspberry Pi OS/Debian (GPL and other licenses): add a `THIRD-PARTY.md` with a pointer to the sources, especially before selling devices with the image preinstalled | 1.0 |
| Update rollback | Roll back ShowPlayPI files only (small) or keep two complete Linux partitions (A/B, doubles the space needed)? Recommended: ShowPlayPI files only | 2.0 |
| Update channels | Stable channel via tags on `main` or a separate `stable` branch? | 2.0 |
| Image size | Companion (about 910 MB installed) and the Ontime image (about 210 MB) make the download about 0.5 GB larger – acceptable, or download them on the first start of the mode instead? | 2.2 |
| Video conversion on the device | Optional (opt-in) background conversion of flagged videos to HEVC, only while nothing plays, the original replaced only after a complete, verified copy? The Pi 5 has no hardware encoder (hours per clip at good quality, full CPU load, heat, needs room for both copies on the drive) – so far the preset for converting on the computer is preferred | 2.1 |

## Decided

- **Companion native, Ontime in Podman** (2026-09-25): Companion runs from its official ARM64 build (own Node,
  USB surfaces work directly, no container overhead on the 1 GB Pi 5); Ontime runs as its official container
  image with Podman (no permanently running daemon, unlike Docker). Both are bundled with the image.
- **OSC port 23878** (2026-09-25) instead of 9000 (the receive port of TouchOSC), so ShowPlayPI does not
  collide with common show-control software; Companion (12321) and Ontime (8888) keep their own OSC ports.
- **Time zone from the internet connection** (2026-09-25): `[SYSTEM] TIMEZONE=auto` is the default – the
  public IP address is looked up at a free GeoIP service (ip-api.com, fallback ipapi.co) at every start.

- **Partition layout** (2026-09-25): boot partition 512 MB (visible, system files hidden), Linux partition
  12 GiB, exFAT media partition "SHOWPLAYPI" on the rest of the card with configuration, configurator and
  media folders; the USB drive and the network share are this partition; self-healing at every start.
  Details under 2.0 (implemented in 1.0.0-beta.3).
- **OSC naming and mode rule** (2026-09-25): `/showplaypi/<command>` for every mode, `/showplaypi/browser/…`,
  `/showplaypi/video/…` and `/showplaypi/audio/…` for modes and services; commands of an inactive mode or
  service are ignored; the handshake (`/showplaypi/hello`) reports mode, services and API version; file
  lists are pushed as JSON on every change. Details in `docs/OSC.md`.
- **Units in OSC** (2026-09-25): all times in milliseconds, all volumes in percent; Companion converts for
  display where useful. Playlists: the main folder is always playlist 1, its subfolders follow alphabetically.
- **Anonymous usage statistics, opt-out** (2026-09-25): install and weekly signal with version, model and
  mode; the server keeps only the country, never the IP address. Details under 3.0.
- **Deleting the configuration restores the delivery state** (2026-09-25): a deleted `showplaypi.ini` is
  replaced by the default configuration – a simple, documented factory reset. Media files are kept.
- **Auto-update policy** (2026-09-24): updates only at boot, only with internet, only stable releases,
  can be disabled (`AUTO_UPDATE=no`), with health check and automatic rollback. Applies to ShowPlayPI and
  to the Ontime/Companion containers (pinned to a major version).
- **OSC changes are session-only** (2026-09-23): everything set via OSC (URL, idle timeout, blackout …)
  applies until the next reboot. **Permanent changes – including a new start page – are only possible
  through the configuration** (configurator, USB drive, SD card, SSH).
  A page set via OSC is the start page of the current session (the idle timeout returns to it).
- **Versioning** (2026-09-23): the first public release is **1.0.0**; until then betas `1.0.0-beta.N`.
  Semantic versioning afterwards (2.0 = incompatible INI change).
- **License: MIT** (2026-09-23). The software is free; revenue comes later from ready-made
  **Raspberry Pi 5 devices with ShowPlayPI preinstalled**. Consequences: the Pi 5 is the primary product
  platform, the out-of-the-box experience and the updater are central, and all interfaces must work
  without any prior knowledge.

## Rejected

- **Native Mac configurator app** (SwiftUI/Platypus): without a paid Apple signature macOS shows a
  security warning on first launch – unsuitable for non-technical users. Replaced by the web interface.
- **Switching modes via OSC:** modes are changed only through the INI.
- **Cue/signal display and clock/timecode display** – already available in Ontime (or as a web page in
  browser mode); timecode via an audio HAT would be too complicated.
- **Stream player mode** (SRT/NDI) – overflow rooms are served by NDI links or fibre. Live streams from an
  HLS source can be shown in browser mode instead (planned HLS player page, release 2.1).
- **NDI output** (sending the picture, e.g. of the browser or Ontime, as an NDI source) – the Pi 5 has no
  hardware video encoder, so only a small preview would be possible next to playback; NDI|HX additionally
  requires the licensed NDI Advanced SDK.
- **Multiview** (several web pages in a grid) – not needed, too complex.
- **DHCP/DNS server** – remains the job of a router.
- **Network monitor** – the device is the wrong place for it.
- **Art-Net/sACN → DMX node** – out of scope.
- **Built-in scheduler** – time-based switching is done from Companion via OSC and triggers (e.g. playlist
  subfolders in the video mode).
