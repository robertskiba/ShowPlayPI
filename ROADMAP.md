# Roadmap

As of 2026-09-23. Structured by releases: each release has a goal, its work items and a
**definition of done**. Security options are attached to the release that introduces the interface
they protect.

## Target picture

A platform for Raspberry Pi 4B and Pi 5 with **separate modes**. Exactly one of them runs at any time:

| Mode | Function |
|---|---|
| `browser` | Full-screen browser for websites and local HTML pages (kiosk) |
| `video` | Full-screen video and still-image player: HEVC/H.264 videos and JPG/PNG images from a folder (playlist) on the media partition, alphabetical, looping, fades through black |
| `ontime` | [Ontime](https://getontime.nl) server (Docker, updates itself on start when online) + full-screen browser showing a timer URL |
| `companion` | Bitfocus Companion (Docker) + optional lightweight browser for the local emulator page |

More modes should be easy to add later.

## Ground rules

- **Usability first:** anyone without Raspberry Pi knowledge must be able to use the image.
  Configuration happens through the Windows configurator, the web interface or the INI file.
- **Open by default, secure by choice:** out of the box everything is simple and open (isolated event
  networks). Every interface gets an optional protection that can be enabled in the INI/configurator.
- The **mode** is set **only** through the INI file, **never through OSC**.
- **OSC in every mode** for live operation; `docs/OSC.md` is the authoritative reference.
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
| **2.4** | Audio loop (background service) | 2.0 |
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
- [ ] Pi 5 specifics: output names, headless resolution, USB gadget over USB-C
- [ ] Booting without network does not delay the browser (currently waits for `network-online.target`,
      possibly ~60 s)
- [ ] VNC performance: check whether the x11vnc options `-sb 0 -nonap -nowait_bog` are needed
- [ ] Power only via USB-C from a PC: check behaviour (gadget reports 250 mA)
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
  - The idle timeout returns to the **session start page**: a page set via `/showplaypi/url` becomes the
    start page for the running session until the next reboot; `/showplaypi/home` discards it and returns
    to the start page from the INI.
  - New OSC command `/showplaypi/idle <seconds>` (`0` = off): enables, changes or disables the idle
    timeout for the running session.

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

**Definition of done:** a user flashes the image with Raspberry Pi Imager, configures it with the
configurator via USB-C (or a text editor on the SD card), and the browser runs on Pi 4B and Pi 5 – with and without a display,
with and without network – on both HDMI outputs.

## 2.0 – Platform

Goal: the internal structure for several modes, without new modes yet. Browser mode keeps working.

- [ ] Mode framework: one systemd target per mode, selected on start through `[SYSTEM] MODE=` in the INI
- [ ] New INI structure: `[SYSTEM] MODE=…`, one section per mode
- [ ] Partition layout: Linux partition fixed (~12 GB, also for Docker images), **media partition**
      (exFAT, readable on Windows/Mac) fills the rest of the card on first boot
- [ ] Shared OSC service for all modes, status replies, OSC feedback subscription
      (`/showplaypi/subscribe`, draft in `docs/OSC.md`); naming scheme for mode-specific commands
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
- [ ] Windows configurator 2.0: mode selection, one tab per mode, security tab
- [ ] **Background services** next to the mode: optional services that run with any mode and never use
      the screen, enabled individually in a `[SERVICES]` section of the INI
- [ ] First background service: **NTP time server** for the show network. Serves time only while the Pi
      itself is synchronised (the Pi 4 has no real-time clock; the Pi 5 has one, but it needs a backup
      battery) – never hands out a wrong time.

**Security options introduced here**
- [ ] OSC password (`/showplaypi/auth <password>`, then accepted from that IP for a limited time;
      Companion module does it automatically) and optional IP allow list.
      Documented honestly: OSC is unencrypted – protects against casual takeover, not against sniffing.
- [ ] Own passwords for login and VNC; passwords entered in the INI are applied on boot and then removed
      from the file
- [ ] SSH can be disabled or restricted to keys; `sudo` with password; USB configuration drive can be
      disabled; firewall (nftables) with only the needed ports

**Definition of done:** switching `MODE` in the INI changes the running mode after a reboot; browser mode
behaves exactly as in 1.0; a device updates itself from the stable channel and can roll back.

## 2.1 – Video & stills mode + web interface

- [ ] Player (mpv, hardware decoding) for **videos and still images** (JPG/PNG) in one playlist, from a
      folder on the media partition, alphabetically in a loop, fades through black
- [ ] **Still duration:** default in the INI (e.g. `[VIDEO] STILL_DURATION=10`); per file overridable with a
      tag in the file name, e.g. `020_Sponsors [15sec].jpg` (also `[15s]`)
- [ ] **Playlists as subfolders** of the media folder (e.g. `morning/`, `noon/`): default playlist in the
      INI, switchable via OSC for the session (`/showplaypi/video/playlist <folder>`) – time-based
      switching is done from Companion via OSC triggers
- [ ] Both HDMI outputs mirrored in video mode too (harder: the player runs without X11 on one output)
- [ ] Note for users: Pi 5 has no H.264 hardware decoder (1080p in software is fine, 4K H.264 is not)
- [ ] OSC: play/pause, next/previous, blackout, status
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
- [ ] Ontime via Docker, updated at boot together with ShowPlayPI (same `AUTO_UPDATE` rules), data in a
      persistent volume; pinned to a major version, previous image kept for rollback
- [ ] Full-screen browser with timer URL (view selectable in the INI)
- [ ] OSC/feedback forwarding where useful (Ontime has its own OSC/HTTP API)
- [ ] Security: Ontime's own access options exposed in the INI

## 2.3 – Companion mode
- [ ] Companion via Docker, updated at boot (same `AUTO_UPDATE` rules), pinned to a major version
      (e.g. 4.x) so no breaking upgrade happens unasked, previous image kept for rollback; verify data survives updates; test USB surfaces (Stream Deck etc.) in the container
- [ ] Optional lightweight browser (e.g. WPE/cog) for the local emulator page with touch, mouse and keyboard
- [ ] Security: Companion's own admin password exposed in the INI

## 2.4 – Audio loop (background service)
- [ ] Plays an audio folder of the media partition in a loop (background music, announcements at a booth),
      e.g. together with the browser mode – not together with the video mode (audio conflict)
- [ ] Outputs: HDMI audio (Pi 4B and Pi 5), 3.5 mm jack (Pi 4B only – the Pi 5 has none), class-compliant
      USB audio adapters (analog output on the Pi 5). DAC HATs are not supported (they conflict with the
      recommended PoE HAT).
- [ ] OSC: play/stop, next, volume, playlist (subfolder) for the session

## 3.0 – Companion module and distribution
- [ ] Companion module built against `docs/OSC.md` (actions and feedbacks for all modes)
- [ ] Download page (konftools.com) with image, configurator, documentation, version history
- [ ] Signed Windows EXE / small installer

---

## Open decisions

| Topic | Question | Needed for |
|---|---|---|
| Third-party licenses | The image bundles Raspberry Pi OS/Debian (GPL and other licenses): add a `THIRD-PARTY.md` with a pointer to the sources, especially before selling devices with the image preinstalled | 1.0 |
| Partition size | Is a fixed ~12 GB Linux partition right? (recommended SD card size then 32 GB+) | 2.0 |
| Update channels | Stable channel via tags on `main` or a separate `stable` branch? | 2.0 |
| OSC naming | Mode commands as `/showplaypi/video/next` or shorter? | 2.0 |
| Companion in Docker | Only if USB surfaces work reliably – otherwise native install | 2.3 |

## Decided

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
- **Multiview** (several web pages in a grid) – not needed, too complex.
- **DHCP/DNS server** – remains the job of a router.
- **Network monitor** – the device is the wrong place for it.
- **Art-Net/sACN → DMX node** – out of scope.
- **Built-in scheduler** – time-based switching is done from Companion via OSC and triggers (e.g. playlist
  subfolders in the video mode).
