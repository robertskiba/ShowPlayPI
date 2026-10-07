# Changelog

All notable changes to ShowPlayPI are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] – 2026-10-07

The first stable release. Compared with 1.0.0-beta.3 it brings a time server for the network and a clock
that is right even without internet, Companion with all modules on board (no internet needed to add
connections), a memory warning, and fixes from the first tests on the Raspberry Pi 4.

### Fixed
- **Clock right after the start:** the clock was only set up to several minutes after the network was up (the
  time service did not notice the connection), and until then every HTTPS connection failed – e.g. Companion
  could not load its module list. The clock is now set as soon as the network is up; public time servers are a
  reserve for the configured one, and in networks that block time servers the time is taken from a web
  server. Companion and Ontime wait briefly for the clock at their start and are restarted once if it is set
  only later.
- Companion and Ontime always use the device's time zone: they start only after the time zone from
  `showplaypi.ini` is set, and both are restarted once when `TIMEZONE=auto` detects a different time zone
  after the start (before, Companion kept the previous time zone until the next restart).
- The picture no longer waits for the network: without a network cable or DHCP server it appeared up to about a
  minute late; now it comes right after the start in every mode (with network about 4.5 s earlier too). A web
  page that is not reachable yet is loaded as soon as it is, and the setup page shows the IP address as soon
  as the device has one.
- **Device names with "_" or spaces** were ignored, and the device kept the name `raspberrypi` (found on a
  Pi 4 at an event with `HOSTNAME=aqlrack_browserpi`). Every character other than letters, digits and hyphens
  now becomes a hyphen (`aqlrack-browserpi`) – on the device and in the configurator, which no longer rejects
  such a name.
- **Lost boot log on devices without a clock:** right after the start the clock stood at an old date, and the
  system log removed everything written until the clock was set as "older than 14 days" – the log of the
  start was gone. The clock now starts at the last known time from the very beginning (or the build of the
  image), and old entries are removed daily without ever touching the log of the current start.
- The `README.txt` on the boot partition was still written for the browser alone: it now describes all four
  modes, the audio player and every section of `showplaypi.ini` with its default.

### Added
- **Memory warning:** a new system monitor logs a warning when the memory runs low – in the Companion mode with
  the number of connections and advice (every Companion connection needs about 25–35 MB; a 1 GB Pi is enough
  for about 5). The configurator shows the RAM recommendation.
- OSC `/showplaypi/system`: CPU load, memory (with warning state), temperature, under-voltage, uptime and free
  space as JSON, in every mode.
- The setup page shows the ShowPlayPI version with its release date and the operating mode.
- **Companion works offline:** the image contains Bitfocus' offline module bundle (all 800+ modules of the
  Companion version), installed on the first start of the Companion mode (about a minute) – connections can be
  added without internet. With internet, newer module versions still come from the store.
- **Time server for the network:** ShowPlayPI serves its time via NTP (UDP port 123) to every device in the
  network – e.g. computers, Companion or clocks in a show network without internet. Announced via Bonjour,
  shown on the setup page, switched off with `[TIME_SERVER] ENABLED=no` (configurator: System tab). Without an
  external time source the device still serves its own clock with a low priority (stratum 10): devices of an
  offline network share the same time, and a device with a better source ignores it. chrony replaces
  systemd-timesyncd; time servers the router announces via DHCP are used as well.
- **Time without internet:** the Pi has no battery-backed clock. At the start the clock is set to the latest
  of: the time saved during the last run (every 10 minutes and at shutdown), the time `showplaypi.ini` was
  last saved on a computer (the date of the file on the `SHOWPLAYPI` drive) and the build time of the image.
  `/showplaypi/system` reports whether the clock is synchronised.

### Known issues
- Only the HDMI port next to the USB-C socket is fully supported; both outputs with the same picture are
  planned for 1.1.
- Video: crossfades fade through black for now; on the Pi 5, H.264 videos are only smooth up to 1080p30.
- Tested mainly on the Raspberry Pi 5; on the Pi 4 the browser mode is tested at an event, the other modes
  are still being tested – fixes follow as 1.0.x.
- Configuration via USB-C depends on the power the computer's USB port delivers.

## [1.0.0-beta.3] – 2026-09-26

ShowPlayPI becomes a playout device with four modes: besides the web browser it now plays videos and still
images, runs Bitfocus Companion or an Ontime timer on the device, and has an audio player for background
music and jingles. The SD card gets a drive `SHOWPLAYPI` for configuration and media, reachable over USB-C,
the network and a card reader. The new modes are first versions, tested on a Raspberry Pi 5.

### Fixed
- **Raspberry Pi 5:** the kiosk did not start (Xorg stopped with "Cannot run in framebuffer mode" because
  the Pi 5 has separate display and 3D devices). Xorg now always uses the vc4 display controller.
- Runtime-generated files (network profile, setup page, host name) are no longer part of the overlay, so
  `deploy.sh` never overwrites a device's network settings.
- `IDLE_CLEAR_SESSION=yes` now also removes the browser's HTTP cache, not only the profile.
- Starting without a network cable (e.g. for configuration over USB-C) no longer reports a failed network
  configuration; the connection comes up as soon as a cable is plugged in.
- Stopping the kiosk took 90 seconds and left X and the browser running (they run in their own login
  session); on a Pi 5 this could hang the device when a computer was connected via USB-C during
  playback. The kiosk now stops within a few seconds.
- **USB configuration drive:** settings saved on the drive could be lost when the USB cable was unplugged
  right after saving (the Pi kept them in memory for up to 30 seconds and lost power with the cable).
  While a computer uses the drive, everything it writes is now on the SD card within about a second, and
  the Windows configurator only reports success once the settings are stored on ShowPlayPI – the cable
  can be unplugged right after saving.

### Added
- **Operating modes:** `[SYSTEM] MODE=browser|video|ontime|companion` in `showplaypi.ini` and in the
  configurator (System tab); only the services of the active mode start.
- **Companion mode (first version):** Bitfocus Companion 5 runs on ShowPlayPI (official ARM64 build, included
  in the image; set up at `http://<device name>.local:8000`). The screen shows Companion's emulator chooser
  (touch, mouse, keyboard); all browser commands keep working. OSC: `/showplaypi/companion/emulators` replies
  with the list of emulators (for a dropdown in a controller), `/showplaypi/companion/emulator <id|name>`,
  `/showplaypi/companion/tablet [pages] [columns] [rows]`, `/showplaypi/companion/restart`. USB surfaces
  such as the Stream Deck get their permissions automatically. Companion's backups are stored in
  `COMPANION/BACKUP` on the drive SHOWPLAYPI.
- **Ontime mode (first version):** an Ontime server runs on ShowPlayPI (official container image, included in
  the image; editor at `http://<device name>.local:4001`). The screen shows the view from `[ONTIME] VIEW`
  (default `timer`, options after `?`); `/showplaypi/ontime/view <view> [options]` shows any view with any
  of its options, e.g. `backstage` `stopCycle=true&extra-info=0-Custom+data`. Ontime uses the device's
  time zone.
- **Audio player (first version):** background music from `AUDIO/LOOP` (subfolders are further
  playlists) and jingles from `AUDIO`, controlled via OSC (`/showplaypi/audio/…`): play, pause, stop and
  volume with fades, next/previous, playhead, playlist switching, repeat and shuffle; a jingle ducks the music
  to a percentage or pauses it, and the music continues afterwards. An optional extra in every mode
  (`[AUDIO] ENABLED=yes`); the music can start automatically
  (`[AUDIO] AUTOSTART=yes`). Settings in the `[AUDIO]` section and on the configurator's Audio tab.
- **Time zone from the internet connection:** `[SYSTEM] TIMEZONE=auto` (the new default) detects the time zone
  from the public IP address at every start (free GeoIP service); without internet the last detected time
  zone is kept. A time zone set in `showplaypi.ini` or the configurator is used as it is.
- Configurator: tab "Companion / Ontime"; an empty target URL means the default page of the mode.
- **Web interfaces in the Windows network view:** running web interfaces (Companion, Ontime) are announced
  via UPnP and appear in Windows Explorer under *Network* (e.g. "showplaypi-e84042 – Companion"); a
  double-click opens them. Only what really answers is announced. `[DISCOVERY] UPNP=no` or the configurator
  (Share tab) switches it off.
- **Video mode (first version):** videos and still images (JPG, PNG, WebP) from the folder `VIDEO` on the
  drive play full-screen in alphabetical order in a loop, with fades; subfolders are further playlists.
  Still images show for `[VIDEO] STILL_DURATION` or the time in their file name (`Sponsors [15sec].jpg`),
  scaled to fit or fill and rotated by their EXIF orientation. New files are picked up while playing.
  Settings in the `[VIDEO]` section and on the configurator's Video tab; OSC control under
  `/showplaypi/video/…` ([docs/OSC.md](docs/OSC.md)), including `list` and `status` replies and a blackout
  with fade. The player runs in the same display session as the browser, so VNC shows it as well.
  Crossfades are in preparation (transitions fade through black for now).
  **Recommended format: H.265/HEVC** – decoded in hardware on the Pi 4 and Pi 5 (1080p60 without dropped
  frames on a Pi 5); the Pi 5 has no H.264 hardware decoder, H.264 up to 1080p30 is fine there.
- **Sound on every output at the same time:** browser and video sound play on both HDMI ports, the headphone
  jack (Pi 4) and a USB sound card (outputs 1-2), also when it is plugged in later; outputs without a device
  that takes sound are skipped. All outputs run at full level, the volume is set centrally.
- OSC commands of an inactive mode are ignored and logged.
- **OSC on UDP port 23878** (instead of 9000): a port that common show-control software does not use by
  default (unlike 9000, the receive port of TouchOSC), so it does not collide with Companion, Ontime or
  controllers on the same device or network. The Companion demo page in `PRESETS` is updated.
- **Drive `SHOWPLAYPI` (media partition):** on the first start ShowPlayPI enlarges its Linux partition to
  12 GiB and creates an exFAT partition in the remaining space (at least 3 GiB, designed for 16 GB cards).
  It holds `showplaypi.ini`, the Windows configurator and the folders `HTML` (local web pages), `VIDEO`,
  `AUDIO`, `AUDIO/LOOP` (for the planned players) and `PRESETS` (Companion page).
  - It is the USB drive over USB-C (replacing the separate small drive image), a network share, and visible
    in a card reader. The system cannot be damaged from it.
  - `showplaypi.ini` exists on the drive, on the boot partition (for editing right after flashing) and as
    the active configuration on the Linux partition; the copy changed since the last start is applied and
    the others are updated. Deleting it from the drive restores the delivery state.
  - Configurator, README and folders are restored automatically if deleted or changed.
  - A newly created drive is always formatted – after re-flashing a card, no files or settings of a
    previous user reappear (the Imager only overwrites the beginning of the card).
  - Local web pages move from `content/` on the boot partition to `HTML/`; the new address is
    `file:///media/showplaypi/HTML/index.html`.
- **Network share** of the drive (Samba, user `admin`, password `admin`): `\\<device name>.local\SHOWPLAYPI`
  on Windows (the device also appears under *Network*), `smb://<device name>.local/SHOWPLAYPI` on the Mac.
  Can be switched off with `[NETWORK_SHARE] ENABLED=no` or in the configurator; pauses while a computer
  uses the drive over USB-C.
- **"Save and Restart"** in the configurator: ShowPlayPI restarts and applies the configuration – right
  away over the network, after ejecting the drive over USB-C. Changes are never applied during operation
  on their own, so a running show is not interrupted.
- Configurator: idle timeout in minutes and seconds (the INI keeps seconds); runs as a normal program
  without the AutoIt tray icon, and a second start brings the open window to the front.
- Setup page: product name as on the boot logo, a third panel for configuration over the network.
- Boot logo and startup image show the name **ShowPlayPI** above the logo.
- **USB configuration mode** (`[SYSTEM] USB_CONFIG_MODE=yes`): while a computer is connected via USB-C,
  ShowPlayPI is a drive, not a player – playback pauses and a status screen shows the state (a computer's
  USB port can hardly ever power a Pi for normal operation). The screen confirms when changes are saved
  ("2 minutes ago" – relative, as the clock is not set without network) and warns about under-voltage.
  After unplugging the cable, ShowPlayPI restarts with the new settings (with PoE or its power supply).
- **Startup image during the whole boot:** the kernel logo disappeared when the display driver took over,
  leaving a black screen for about ten seconds. The startup image is now shown until the kiosk starts.
  Boot messages (e.g. the file system check) no longer appear over it: in quiet mode the console moves to
  the invisible tty3 and the cursor is hidden.
- `[SYSTEM] BOOT_MESSAGES=yes` shows the system messages instead of the startup image (troubleshooting);
  also available in the Windows configurator, together with the low-power mode switch.
- **Automatic data hygiene** – devices are often passed on without a reset:
  - browser caches, history and temporary files are removed at least every 14 days (while the browser
    keeps running, if necessary)
  - when the start page in `showplaypi.ini` changes, the browser starts completely clean (cookies, logins,
    stored site data); pages switched via OSC during a show do not trigger this
  - temporary files in `/var/tmp` are kept for 14 days at most, the system log is limited to 100 MB and
    14 days
- **Unique device names:** the default name `showplaypi` becomes `showplaypi-` plus the last six digits of
  the MAC address (e.g. `showplaypi-e84042`), so several devices never share a name – even if they are not
  online at the same time. A name set in `showplaypi.ini` is used as it is.
- The system files on the SD card's boot partition are hidden, so only `showplaypi.ini`, the README,
  `version.txt` and `Clear-SD-Card.cmd` are visible when the card is inserted into a computer.
- `Clear-SD-Card.cmd` on the boot partition turns the card back into an empty card (one partition
  `SDCARD`) – after a confirmation, and only on the ShowPlayPI card it is started from.
- `deploy.sh` uses the SSH key `~/.ssh/showplaypi_ed25519` automatically if it exists (no password prompt).
- The build writes a list for Raspberry Pi Imager next to every image (`*.rpi-imager.json`, with an icon),
  so ShowPlayPI can appear in the Imager's OS list. It switches off the Imager's OS customisation, which
  would interfere with ShowPlayPI's own configuration.

### Known issues
- Tested on a Raspberry Pi 5 so far; the Raspberry Pi 4 is not tested yet with this version.
- Only the HDMI port next to USB-C is fully supported; both outputs with the same picture are planned.
- Video: crossfades fade through black for now; on the Pi 5, H.264 videos are only smooth up to 1080p30
  (H.265/HEVC is decoded in hardware up to 4K60).
- Companion on a 1 GB Pi: about 25–35 MB per connection – with about 15 connections the memory is nearly used
  up, with 30 the device stalls. Use a Pi with 2 or 4 GB for larger Companion setups.
- Without a network connection the picture may take up to about a minute longer to appear.
- See `ROADMAP.md` ("Open before 1.0.0") for the complete list.

## [1.0.0-beta.2] – 2026-09-24

### Added
- URLs with umlauts and other non-ASCII characters work everywhere (OSC, `showplaypi.ini`, configurator):
  they are converted to their ASCII form (international host names like Chromium, percent-encoded path
  and query), so browser, watchdog and idle timeout always agree on the address.
- OSC strings are decoded as UTF-8 with a Latin-1 fallback for older senders.

### Changed
- Website and support contact: https://konftools.com · support@konftools.com.

## [1.0.0-beta.1] – 2026-09-24

First beta of ShowPlayPI.

### Added
- **Full-screen kiosk browser** (Chromium on a minimal X11/Openbox session) for `http://`, `https://` and
  local `file://` pages, with a local setup page when no URL is configured.
- **Headless operation:** always outputs a signal (1080p60 by default, configurable), or the display's
  preferred mode via EDID.
- **Website watchdog:** keeps checking the page after a server outage and reloads it when it is back;
  optional periodic reload; Chromium restarts automatically after a crash.
- **Idle timeout for kiosks:** returns to the start page after a configurable time without touch, mouse or
  keyboard input (`IDLE_TIMEOUT`, `IDLE_ACTION=home|reload`, `IDLE_CLEAR_SESSION` to clear cookies, form
  data and logins). Display-only screens are never reset.
- **OSC remote control** on UDP port 9000: `/showplaypi/url`, `/showplaypi/home`, `/showplaypi/refresh`,
  `/showplaypi/restart`, `/showplaypi/blackout`, `/showplaypi/idle` – all changes last until the next
  restart ([docs/OSC.md](docs/OSC.md)). Ready-made Bitfocus Companion demo page.
- **VNC** remote view of the actual screen.
- **Configuration** in one file, `showplaypi.ini`: on the SD card or – while the Pi is running – on a virtual
  USB drive `SHOWPLAYPI` via USB-C, including the **Windows configurator** `ShowPlayPI-Configurator.exe`.
- Network (DHCP or static IPv4, additional DNS), hostname, time zone and time server.
- Boot splash, SSH login banner with version, `showplaypi-refresh` to apply changes without rebooting.
- Reproducible image build from the official Raspberry Pi OS Lite (`build/build.sh`), development
  deployment to a running Pi (`deploy.sh`), package manifest next to every image.
- Documentation: README, OSC reference, roadmap, third-party licenses, MIT license.

### Known issues
- Only the HDMI port next to USB-C is fully supported; mirroring to both outputs is planned for 1.0.
- Raspberry Pi 5 support is not tested yet.
- Without a network connection the browser may start with a delay of up to ~60 s.
- Configuration via USB-C depends on the power the computer's USB port delivers.
- See `ROADMAP.md`, release 1.0, for the complete list.

[Unreleased]: https://github.com/robertskiba/ShowPlayPI/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/robertskiba/ShowPlayPI/compare/v1.0.0-beta.3...v1.0.0
[1.0.0-beta.3]: https://github.com/robertskiba/ShowPlayPI/compare/v1.0.0-beta.2...v1.0.0-beta.3
[1.0.0-beta.2]: https://github.com/robertskiba/ShowPlayPI/compare/v1.0.0-beta.1...v1.0.0-beta.2
[1.0.0-beta.1]: https://github.com/robertskiba/ShowPlayPI/releases/tag/v1.0.0-beta.1
