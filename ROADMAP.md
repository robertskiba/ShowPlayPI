# Roadmap

As of 2026-09-26. Structured by releases: each release has a goal, its work items and a
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

**Extras** can be switched on next to any mode and never take over the screen: the **audio player**
(background music and jingles), later an NTP time server, HDMI-CEC display control, GPIO and Companion
Satellite.

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
- **Updates** happen only at boot and only with internet; they touch ShowPlayPI scripts and packages, never
  the whole operating system, and can be rolled back.

## Overview

| Release | Goal | Depends on |
|---|---|---|
| Groundwork ✅ | Repository, build, deploy, review (no release) | – |
| **1.0** | **First public release:** four modes (browser, video, Companion, Ontime) and the audio player as first versions, drive `SHOWPLAYPI`, Windows configurator – betas `1.0.0-beta.N`, then `1.0.0-rc.N` | Groundwork |
| **1.1** | Display and kiosk: both HDMI outputs, rotation, URL allow list, Bonjour, status page | 1.0 |
| **1.2** | The modes, second round: shared OSC service with feedbacks, video crossfades, Companion/Ontime without browser, file checks | 1.0 |
| **2.0** | Updates and security: auto-update (ShowPlayPI, Companion, Ontime), factory reset, own passwords, configurator wizard | 1.x |
| **2.1** | Web interface: configuration and media upload from any device | 2.0 |
| **2.2** | More extras: NTP time server, HDMI-CEC, GPIO, thumbnail | 1.2 |
| **3.0** | Companion module, distribution | 1.2 |
| **3.1** | Companion Satellite: USB control surfaces on the Pi for a remote Companion (extra) | 2.0 |

Release path to 1.0.0 (decided 2026-09-26): `1.0.0-beta.3` (first public beta) → fixes from the tests on
Pi 5 and Pi 4 → `1.0.0-rc.1` → `1.0.0` when no more errors turn up.

---

## Groundwork ✅ (not a release)
- [x] `deploy.sh` (development on a running Pi), `build/build.sh` (reproducible image), `build/compare.sh`
- [x] Repository on GitHub, all content in English
- [x] Code review of all scripts (2026-09-23); findings fixed, hardware questions moved to 1.0
- [x] OSC commands documented (`docs/OSC.md`)

## 1.0 – First public release

Iterated as betas (`1.0.0-beta.1`, `-beta.2`, `-beta.3` …) until the definition of done is met.
**beta.3** brings everything below that is marked as done – most of it first versions tested on a Pi 5.

### Open before 1.0.0

- [ ] **Test the built image from factory on Pi 5 and Pi 4B** – flashing with the Imager, first start
      (partitions, drive `SHOWPLAYPI`), every mode, audio player, USB configuration mode, network share, OSC,
      VNC, watchdog
- [ ] **Pi 4B:** USB configuration mode, headphone jack, video player (H.264 hardware decoding), Companion and
      Ontime – so far only tested on the Pi 5
- [ ] **Booting without network** does not delay the picture (the X session waits for
      `network-online.target`, possibly up to about a minute)
- [ ] **Companion out of memory:** measured on the 1 GB Pi 5 – every connection is a Node process of its own
      (about 25–35 MB); with 30 connections the device stalled and was reset by the watchdog. Before 1.0.0: a
      warning when the memory runs low (log, OSC status), the RAM recommendation in README and configurator
      (1 GB up to about 5 connections, 2 GB typical events, 4 GB large setups); measure 2/4 GB and real
      modules (ATEM, vMix …)
- [ ] Power only via USB-C from a PC: the Pi 4 works (USB configuration mode); the Pi 5 does not start at all
      from a PC USB port (red LED – the bootloader never runs, no software can fix that) – documented
- [ ] **Power over Ethernet:** official PoE HATs on Pi 4B and Pi 5 (PoE+ recommended) – the Pi 5 test device
      runs on PoE; verify stable operation under load and the HAT fan control
- [ ] Version number visible on the setup page (INI, configurator and SSH banner show it)
- [ ] **Publish:** delete and re-create the GitHub repository before making it public (so no commits of the
      old history remain reachable), push the clean history, release on GitHub with image, checksum and
      configurator EXE
- [ ] Publish the Imager list at a permanent URL, test it with `rpi-imager --repo <url>`, then apply for the
      official Imager list (form linked at the end of the Imager's `doc/schema-notes.md`)

**Definition of done:** a user flashes the image with Raspberry Pi Imager, configures it with the
configurator via USB-C (or a text editor on the SD card), chooses a mode, and the device runs on Pi 4B and
Pi 5 – with and without a display, with and without network.

### Platform ✅
- [x] **Operating modes:** `[SYSTEM] MODE=browser|video|ontime|companion` in the INI (configurator: System
      tab), read by `showplaypi-mode`, which writes flag files at every start; the units of each mode start
      through `ConditionPathExists=` on them (`ExecCondition=` with `Restart=always` restarted skipped units
      in a loop, and in the kiosk unit `startx` even ran despite the failed condition)
- [x] New INI structure: `[SYSTEM] MODE=…`, one section per mode and extra
- [x] **Partition layout** (tested on a Pi 5, 2026-09-25):
  - **Boot partition** (FAT, 512 MB as in Raspberry Pi OS). Hiding it from computers is not possible:
    Windows mounts every FAT partition on removable media whatever its MBR type (tested with `0xef` and
    `0x1c`), and the Pi 5 bootloader refuses `0x1c`. Instead its system files are hidden and it carries
    only `showplaypi.ini`, `README.txt`, `version.txt` and `Clear-SD-Card.cmd`.
  - **Linux partition** (ext4): **12 GiB** (system, Companion, container images, room for updates).
  - **Media partition "SHOWPLAYPI"** (**exFAT**, no 4 GB file limit, read/write on Windows and macOS):
    the rest of the card, created on the first start (`showplaypi-media`, takes seconds – nothing is
    moved). **Designed for 16 GB cards:** it gets at least 3 GiB – on small cards the Linux partition
    shrinks for it (down to 10.5 GiB), because "16 GB" cards differ in real size (about 14.4–14.9 GiB).
    Contents: `showplaypi.ini`, configurator, README, `HTML/`, `VIDEO/`, `AUDIO/`, `AUDIO/LOOP/`,
    `PRESETS/`, `COMPANION/BACKUP/` (Companion mode).
  - **Three copies of `showplaypi.ini`:** boot partition (edit right after flashing), media partition
    (USB, network, card reader) and the active configuration on the Linux partition. At every start the
    copy changed since the last start wins (the media partition if both changed) and the others follow.
- [x] **USB configuration drive = the media partition:** when a computer connects, ShowPlayPI unmounts it and
      offers it over USB-C; after ejecting or unplugging it is mounted again. Everything the computer writes
      is on the SD card within about a second; the configurator only reports success once it is stored.
- [x] **USB configuration mode** (`USB_CONFIG_MODE=yes`): whenever a computer is connected via USB-C,
      ShowPlayPI is a drive, not a player – the mode's services stop, a status screen is shown, CPU in
      power-save mode, Wi-Fi/Bluetooth off. Decided instead of detecting a weak supply: a PC port can hardly
      ever power a Pi, the Pi 4 does not report its supply current, and an under-voltage is only noticed once
      it has happened. After unplugging, ShowPlayPI restarts with the new settings (PoE or power supply).
- [x] **Network share** of the media partition (Samba, `admin`/`admin`, `[NETWORK_SHARE] ENABLED`), shown in
      the Windows network view (WS-Discovery via wsdd2) and the macOS Finder (Bonjour); pauses while the
      drive is used over USB-C; without directory leases, so files the device writes itself appear at once.
      "Save and Restart" in the configurator applies changes right away.
- [x] **UPnP announcement** of every running web interface (Companion, Ontime) – found in the Windows network
      view, opened with a double-click; `[DISCOVERY] UPNP=no` switches it off
- [x] **Self-healing at every start** – the device always stays operational, if need be in its delivery
      state; the last working configuration is kept on the Linux partition:
  - configurator, README and presets are replaced if missing or changed; missing folders re-created
  - **deleted `showplaypi.ini` = delivery state** (media files are kept)
  - invalid or damaged `showplaypi.ini`: the device runs with the last working configuration
  - media partition without file system: formatted again; with a foreign file system: not touched
- [x] **Automatic data hygiene** (devices are far too often passed on without a reset): browser caches,
      history and temporary files deleted at least every 14 days; cookies and site data deleted when the start
      page in the configuration changes (not on URL changes via OSC); journal limited to 100 MB and 14 days
- [x] **Unique device names** (`showplaypi-` plus the last six digits of the MAC address), quiet boot with the
      startup image, `Clear-SD-Card.cmd` on the boot partition
- [x] **Time zone from the internet connection** (`[SYSTEM] TIMEZONE=auto`, default)
- [x] **OSC on UDP port 23878** (was 9000); commands of inactive modes are ignored

### Browser ✅
- [x] Pi 5: Xorg failed to start (separate display/3D devices) – fixed with an Xorg OutputClass for vc4
- [x] **Idle timeout** – return to the start page (`IDLE_TIMEOUT`, `IDLE_ACTION=home|reload`,
      `IDLE_CLEAR_SESSION`), session start page via OSC, `/showplaypi/browser/idle <milliseconds>`;
      to be verified on touch hardware
- [x] **UTF-8 URLs** with umlauts and other non-ASCII characters (IDNA host names, percent-encoded path and
      query, 32 automated test cases)
- [x] Companion and Ontime mode show their view when no own URL is set; an empty URL is valid

### Video mode (first version) ✅
- [x] `showplaypi-video`: mpv full-screen in the X session (VNC and display settings work as in browser
      mode); videos and still images from `VIDEO/` in alphabetical order in a loop, subfolders as playlists,
      autostart, stills with duration tag (`[15sec]`), fit/fill, EXIF rotation, fades through black; all OSC
      commands of `docs/OSC.md` with `list` and `status` replies
- [x] Measured on the Pi 5 (1 GB, 2026-09-25): 1080p60 and 4K60 HEVC with hardware decoding without dropped
      frames at low CPU load (`profile=fast`, the same with and without X); 1080p60 H.264 in software drops
      frames in demanding scenes – documentation recommends HEVC, H.264 only up to 1080p30 on the Pi 5
- [x] **Sound on all outputs at once** (PipeWire combine sink: both HDMI ports, the Pi 4 jack, USB sound cards
      on outputs 1-2, every output at full level; rtkit for real-time audio threads)

### Companion mode (first version) ✅
- [x] Companion 5 as the official ARM64 build in `/opt/companion` (`showplaypi-companion.service`, config in
      `/home/admin/companion`), bundled with the image; the browser always starts with the emulator chooser
- [x] OSC `emulators` (list as JSON for a dropdown), `emulator <id|name>`, `tablet`, `restart`
- [x] Companion's own udev rules for USB surfaces installed automatically (`COMPANION_SYNC_UDEV_RULES_COMMAND`)
- [x] **Backups on the SHOWPLAYPI drive:** Companion's backup folder is a link to `COMPANION/BACKUP/` (no
      change to Companion's configuration); the log stays in the system journal

### Ontime mode (first version) ✅
- [x] Ontime 4 in a Podman container (`showplaypi-ontime.service`, host network, data in `/home/admin/ontime`,
      time zone from the device), image bundled and loaded on the first start – works offline; about 95 MB RAM
- [x] The browser shows `[ONTIME] VIEW` (options after `?`); OSC `/showplaypi/ontime/view <view> [options]`
      passes every view option on

### Audio player (first version, extra) ✅
- [x] `showplaypi-audio` with two mpv players (music and jingles) through PipeWire on all outputs; an extra in
      every mode (`[AUDIO] ENABLED=yes`), no mode of its own
- [x] `AUDIO/` jingles, `AUDIO/LOOP/` playlists (subfolders one level deep); WAV, MP3, FLAC, OGG/Opus, M4A/AAC
- [x] Fades in the background for play, pause, stop and volume; a jingle ducks the music (`DUCK_LEVEL` percent)
      or pauses it, and the music continues afterwards; autostart opt-in; volumes always in percent
- [x] The complete OSC command set of `docs/OSC.md` with `list` and `status` replies; `[AUDIO]` section and
      Audio tab in the configurator; about 10 MB RAM idle, about 55 MB while playing

### Release ✅
- [x] `LICENSE` (MIT), `CHANGELOG.md`, `THIRD-PARTY.md` (incl. Companion and Ontime)
- [x] Build writes a package manifest (`dpkg-query -W`) and the Raspberry Pi Imager list next to every image
- [x] README for users; developer notes in `docs/DEVELOPMENT.md`

## 1.1 – Display and kiosk

- [ ] **Both HDMI outputs** always carry a signal (at least 1080p60 headless, configurable) and are
      **mirrored** – in every mode (the video player runs in the X session like the browser); with different
      displays a common resolution, if in doubt the configured one or 1080p60
- [ ] Pi 5 specifics: headless resolution, which HDMI port is detected as connected; 4K output mode
- [ ] **Screen rotation** for portrait signage and kiosks: `[DISPLAY] ROTATION=0|90|180|270`, also in the
      configurator; touch input rotated accordingly; applies to both HDMI outputs
- [ ] **URL allow list** so visitors cannot follow a link out of the kiosk content into the internet:
      `[BROWSER] ALLOWED_URLS=` (domains/URL patterns, empty = everything allowed), also in the configurator.
      Implemented through Chromium policies (URL allow/block list); the session start page is always allowed;
      optionally also disable the context menu (right click / long press)
- [ ] **Bonjour/mDNS announcement** so controllers find devices automatically (Companion modules can
      discover devices via Bonjour): advertise the OSC service (`_osc._udp`, port 23878) and a ShowPlayPI
      service with TXT records (name, version, mode) via Avahi
- [ ] **Setup/status page:** IP, hostname, URL, mode, watchdog/OSC/VNC status, version; a note when the
      configuration was invalid, a warning when the media partition has a foreign file system
- [ ] **Network recovery:** if a static IP does not work, the device stays reachable (e.g. an additional
      link-local address)
- [ ] **Blackout always fades** (all modes): default fade time in the INI (`[DISPLAY] BLACKOUT_FADE=500`),
      per command in milliseconds
- [ ] VNC performance: check whether the x11vnc options `-sb 0 -nonap -nowait_bog` are needed
- [ ] Browser mode: bundled **HLS player page** for live streams (Chromium cannot play `.m3u8` natively),
      e.g. `URL=file:///usr/share/showplaypi/hls.html?src=https://…`

## 1.2 – The modes, second round

**Shared OSC service**
- [ ] Feedback subscription with handshake (`/showplaypi/subscribe`, `/showplaypi/hello`),
      `/showplaypi/status`, `/showplaypi/identify` (device name and IP on the screen, to tell displays apart),
      `/showplaypi/system` (CPU, RAM, temperature, under-voltage, free space), `/showplaypi/reboot "reboot"`
      (emergency restart); file lists pushed as JSON on every change (draft in `docs/OSC.md`)
- [ ] Feedbacks of the video player, the audio player and the Companion mode (state, elapsed and remaining
      time, volumes, emulator list)

**Video**
- [ ] **Crossfades** between entries (`[VIDEO] TRANSITION=crossfade`, currently through black)
- [ ] **Detect files that will not play smoothly:** check codec, resolution and frame rate against the
      hardware (e.g. Pi 5: H.264 above 1080p30) and flag them – in the log, in the OSC file list (e.g.
      `"playback": "may-stutter"`) and later in the web interface; nothing is converted on the device
- [ ] **HandBrake preset "ShowPlayPI HEVC"** in `PRESETS/` on the drive: converts videos into the recommended
      format on the computer (the Pi 5 has no hardware encoder: 1080p60 to HEVC `ultrafast` ran at about 0.3×
      real time, measured 2026-09-25); README and drive README explain the one-time import
- [ ] Durations of all files in the file lists (not only after they have played once)

**Companion and Ontime**
- [ ] **Browser switchable off** (`[DISPLAY] BROWSER=no`): only Companion/Ontime runs, the screen shows a text
      console with device name, IP address and the web address – frees about 250 MB for Companion connections
- [ ] Test USB surfaces (Stream Deck etc.) on the device
- [ ] `/showplaypi/companion/backup` (a backup right away)
- [ ] Ontime: OSC/feedback forwarding where useful (Ontime has its own OSC/HTTP API)
- [ ] Security: Companion's admin password and Ontime's access options exposed in the INI

**Audio**
- [ ] Test with a USB sound card with more than two outputs, the Pi 4 headphone jack and next to the video mode
- [ ] Durations of all files in the file lists

## 2.0 – Updates and security

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
  - Requires the repository (or at least its releases) to be public.
- [ ] **Companion updates:** download the newest build within the major version (5.x) from Bitfocus' package
      API in the background, switch at the next start, back up the configuration before, check that Companion
      comes up, roll back to the previous version otherwise; major versions only after being enabled
- [ ] **Ontime updates:** same rules, pinned to the major version (tag `v4`), previous image kept for rollback
- [ ] **Full factory reset** (`[SYSTEM] FACTORY_RESET=yes`, set by a button in the configurator with a clear
      warning and confirmation, or by hand in the INI; never via OSC). On the next start, before anything
      else runs:
  - the media partition is formatted and filled with the defaults again – **all media files are deleted**
  - the configuration is reset to the delivery state (which also removes the flag, so it runs only once)
  - runtime data is removed: browser profile, Companion and Ontime data, synchronisation state, network
    profiles; new SSH host keys are generated
  - then the device restarts once and comes up as on the first start after flashing
  - For rental devices and before selling a device. Difference to deleting `showplaypi.ini`: that only
    resets the configuration and keeps the media files.
- [ ] **Windows configurator 2.0 as a wizard:** goes through all settings step by step instead of tabs, and
      only asks what matters for the chosen mode
  - The mode is chosen first with **four large picture buttons**: browser, video, Companion and Ontime
  - The **audio player** is a separate step: "Enable the audio player?" – an optional extra in every mode;
    its settings (background playlist, jingles) only follow when enabled
  - Then the mode's settings, network, display, remote access and security (own passwords, lockable
    interfaces), and a summary page before saving ("Save" / "Save and Restart")
  - Experienced users can jump to any step directly; the INI stays the single source of all settings
- [ ] Anonymous usage statistics (see 3.0) can count the update check instead of a separate request

**Security options**
- [ ] OSC password (`/showplaypi/auth <password>`, then accepted from that IP for a limited time;
      Companion module does it automatically) and optional IP allow list; this also protects
      `/showplaypi/reboot`. Documented honestly: OSC is unencrypted – protects against casual takeover, not
      against sniffing.
- [ ] Own passwords for login, VNC and the network share; passwords entered in the INI are applied on boot and
      then removed from the file
- [ ] SSH can be disabled or restricted to keys; `sudo` with password; USB configuration drive can be
      disabled; firewall (nftables) with only the needed ports

**Definition of done:** a device updates itself (ShowPlayPI, Companion, Ontime) from the stable channel and
can roll back; every interface can be locked in the INI and the configurator.

## 2.1 – Web interface

- [ ] **Web interface** at `http://showplaypi.local`, via the regular network **and over USB-C**
      (USB gadget additionally offers a network connection): same settings as the Windows configurator,
      plus media upload/delete/order for video and audio. This is also the configurator for Mac, iPad and
      phones – no install, no Gatekeeper warning.
- [ ] Announced via UPnP like the other web interfaces, with the ShowPlayPI logo
- [ ] Security: optional password for the web interface

**Definition of done:** a user configures the device and uploads media from a Mac, iPad or phone without
installing anything.

## 2.2 – More extras

Optional services next to any mode, never using the screen, each switched on in its own INI section.

- [ ] **NTP time server** for the show network. Serves time only while the Pi itself is synchronised (the
      Pi 4 has no real-time clock; the Pi 5 has one, but it needs a backup battery) – never hands out a wrong
      time.
- [ ] **HDMI-CEC display control** via OSC – the complete, universal set and nothing more: power on/off
      (standby), volume up/down, mute, input/source selection; for both HDMI outputs. Feedback of the
      display's power state where the display reports it.
- [ ] **GPIO inputs and outputs (GPI/GPO)** via OSC: inputs (buttons, contact closures) send OSC messages and
      feedbacks to subscribers, outputs (relays, lamps) are switched via OSC and report their state; pins,
      direction, debounce and names configured in the INI. Check compatibility with the PoE HATs, which cover
      the GPIO header.
- [ ] **Thumbnail on request via OSC:** a small preview image of what is currently on screen, sent to the
      requesting subscriber (e.g. for a Companion button). Only captured on request, small size, rate
      limited – no permanent load on the device.

## 3.0 – Companion module and distribution
- [ ] Companion module built against `docs/OSC.md` (actions and feedbacks for all modes, dropdowns from the
      file and emulator lists)
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
- [ ] Signed Windows EXE / small installer

## 3.1 – Companion Satellite (extra)

Stream Deck and other USB control surfaces plugged into the Pi work with a **Companion on another computer**
– e.g. a Stream Deck at the lectern next to a ShowPlayPI display, while Companion runs in the control room.

- [ ] Optional service `[SATELLITE] ENABLED=yes|no` (off by default), a step of its own in the configurator
      wizard; available in **every mode except `companion`** (there the surfaces connect to the local
      Companion directly)
- [ ] Bitfocus Companion Satellite as its official ARM64 headless build, bundled with the image (MIT) and
      updated like Companion
- [ ] Target: `[SATELLITE] HOST=<IP address or name>` (Companion's Satellite port 16622 by default,
      `PORT` optional); if empty, find a Companion on the network automatically (mDNS) where Satellite
      supports it
- [ ] USB permissions for the surfaces as in the Companion mode (udev rules, group `plugdev`)
- [ ] Status in the OSC status feedback and on the setup page (connected to … / not connected)
- [ ] Measure the load next to the browser and the video mode on the 1 GB Pi 5
- [ ] Security: if Satellite offers its own configuration interface, it gets an optional password like every
      other interface

## Open decisions

| Topic | Question | Needed for |
|---|---|---|
| Image size | Companion (about 910 MB installed) and the Ontime image (about 210 MB) make the download about 0.4 GB larger (now 1.4 GB) – acceptable, or download them on the first start of the mode instead? | 1.0 |
| Update rollback | Roll back ShowPlayPI files only (small) or keep two complete Linux partitions (A/B, doubles the space needed)? Recommended: ShowPlayPI files only | 2.0 |
| Update channels | Stable channel via tags on `main` or a separate `stable` branch? | 2.0 |
| Video conversion on the device | Optional (opt-in) background conversion of flagged videos to HEVC, only while nothing plays, the original replaced only after a complete, verified copy? The Pi 5 has no hardware encoder (hours per clip at good quality, full CPU load, heat, needs room for both copies on the drive) – so far the preset for converting on the computer is preferred | 1.2 |

## Decided

- **Release path** (2026-09-26): `1.0.0-beta.3` is the first public beta; after the tests on Pi 5 and Pi 4
  `1.0.0-rc.1`, then `1.0.0`. The roadmap was reorganised around what is already in 1.0.
- **Audio player as an extra, not a mode** (2026-09-25): switched on with `[AUDIO] ENABLED=yes` in any of the
  four modes; PipeWire mixes it with the video mode.
- **Companion RAM recommendation** (2026-09-26, measured on the 1 GB Pi 5): 1 GB up to about 5 connections,
  2 GB for typical events, 4 GB for large setups – every connection is a Node process of its own.
- **Companion native, Ontime in Podman** (2026-09-25): Companion runs from its official ARM64 build (own Node,
  USB surfaces work directly, no container overhead on the 1 GB Pi 5); Ontime runs as its official container
  image with Podman (no permanently running daemon, unlike Docker). Both are bundled with the image.
- **Video player in the X session** (2026-09-25): measured with and without X – no difference in dropped
  frames or load; in the X session VNC, the display settings and later both HDMI outputs work as in browser
  mode.
- **OSC port 23878** (2026-09-25) instead of 9000 (the receive port of TouchOSC), so ShowPlayPI does not
  collide with common show-control software; Companion (12321) and Ontime (8888) keep their own OSC ports.
- **UPnP announcement of the web interfaces** (2026-09-25): every running web interface on the device
  (Companion, Ontime, later the configuration web interface) is announced via SSDP, so it can be found in
  the Windows network view; `[DISCOVERY] UPNP=no` switches it off.
- **Time zone from the internet connection** (2026-09-25): `[SYSTEM] TIMEZONE=auto` is the default – the
  public IP address is looked up at a free GeoIP service (ip-api.com, fallback ipapi.co) at every start.
- **Partition layout** (2026-09-25): boot partition 512 MB (visible, system files hidden), Linux partition
  12 GiB, exFAT media partition "SHOWPLAYPI" on the rest of the card with configuration, configurator and
  media folders; the USB drive and the network share are this partition; self-healing at every start.
- **OSC naming and mode rule** (2026-09-25): `/showplaypi/<command>` for every mode, `/showplaypi/browser/…`,
  `/showplaypi/video/…`, `/showplaypi/companion/…`, `/showplaypi/ontime/…` and `/showplaypi/audio/…` for
  modes and extras; commands of an inactive mode or extra are ignored; the handshake (`/showplaypi/hello`)
  reports mode, extras and API version; file lists are pushed as JSON on every change. Details in
  `docs/OSC.md`.
- **Units in OSC** (2026-09-25): all times in milliseconds, all volumes in percent; Companion converts for
  display where useful. Playlists: the main folder is always playlist 1, its subfolders follow alphabetically.
- **Anonymous usage statistics, opt-out** (2026-09-25): install and weekly signal with version, model and
  mode; the server keeps only the country, never the IP address. Details under 3.0.
- **Deleting the configuration restores the delivery state** (2026-09-25): a deleted `showplaypi.ini` is
  replaced by the default configuration – a simple, documented factory reset. Media files are kept.
- **Auto-update policy** (2026-09-24): updates only at boot, only with internet, only stable releases,
  can be disabled (`AUTO_UPDATE=no`), with health check and automatic rollback. Applies to ShowPlayPI,
  Companion and Ontime (pinned to a major version).
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

- **Audio mode as a fifth mode** (2026-09-25) – the audio player is an extra that runs next to any mode.
- **Native Mac configurator app** (SwiftUI/Platypus): without a paid Apple signature macOS shows a
  security warning on first launch – unsuitable for non-technical users. Replaced by the web interface.
- **Switching modes via OSC:** modes are changed only through the INI.
- **Cue/signal display and clock/timecode display** – already available in Ontime (or as a web page in
  browser mode); timecode via an audio HAT would be too complicated.
- **Stream player mode** (SRT/NDI) – overflow rooms are served by NDI links or fibre. Live streams from an
  HLS source can be shown in browser mode instead (planned HLS player page, release 1.1).
- **NDI output** (sending the picture, e.g. of the browser or Ontime, as an NDI source) – the Pi 5 has no
  hardware video encoder, so only a small preview would be possible next to playback; NDI|HX additionally
  requires the licensed NDI Advanced SDK.
- **Companion log files on the drive** (2026-09-26) – Companion writes no log files of its own; its log stays
  in the system journal.
- **Multiview** (several web pages in a grid) – not needed, too complex.
- **DHCP/DNS server** – remains the job of a router.
- **Network monitor** – the device is the wrong place for it.
- **Art-Net/sACN → DMX node** – out of scope.
- **Built-in scheduler** – time-based switching is done from Companion via OSC and triggers (e.g. playlist
  subfolders in the video mode).
