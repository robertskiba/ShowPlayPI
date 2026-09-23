# Changelog

All notable changes to ShowPlayPI are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

First beta of ShowPlayPI – will be released as `1.0.0-beta.1`.

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

[Unreleased]: https://github.com/robertskiba/ShowPlayPI/commits/main
