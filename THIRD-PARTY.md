# Third-party software

The ShowPlayPI scripts, configuration files and the Windows configurator in this repository are
licensed under the [MIT license](LICENSE).

The **ShowPlayPI image**, however, is a complete operating system. Besides ShowPlayPI it contains a large
number of third-party programs, each under its own license – many of them under the GNU General Public
License (GPL) or GNU Lesser General Public License (LGPL). ShowPlayPI does not change the license of any
of these programs. The MIT license of this repository applies only to ShowPlayPI's own files.

## Base system

| Component | Origin | License |
|---|---|---|
| Raspberry Pi OS Lite (64-bit), based on Debian 13 "trixie" | Raspberry Pi Ltd / Debian | various, per package |
| Linux kernel | Raspberry Pi Ltd | GPL-2.0 |
| Raspberry Pi firmware and bootloader files | Raspberry Pi Ltd / Broadcom | proprietary, redistributable (see `LICENCE.broadcom` on the boot partition) |

The exact base image is pinned in [`build/config.env`](build/config.env)
(`2026-06-18-raspios-trixie-arm64-lite.img.xz` and its SHA-256 checksum).

## Main additional components

Installed by ShowPlayPI on top of the base system (see [`packages.txt`](packages.txt)); dependencies are
installed automatically by the package manager.

| Component | Purpose | License (main) |
|---|---|---|
| Chromium | kiosk browser | BSD-3-Clause and others |
| X.Org X server, xinit, X11 utilities | graphical session | MIT/X11 |
| Openbox | window manager | GPL-2.0-or-later |
| x11vnc | VNC remote view | GPL-2.0-or-later |
| xdotool | browser reload/control | BSD-3-Clause |
| unclutter-xfixes | hides the mouse pointer | MIT |
| Midnight Commander (mc) | file manager/editor on the console | GPL-3.0-or-later |
| ImageMagick | boot splash conversion | ImageMagick License |
| Python 3 | OSC service | PSF License |
| systemd, NetworkManager | system and network management | LGPL-2.1-or-later / GPL-2.0-or-later |

This table is an overview. **The authoritative license information for every package** is included in
the image itself, in `/usr/share/doc/<package>/copyright`. The list of installed packages and versions
can be displayed on the device with:

```bash
dpkg-query -W -f='${Package} ${Version}\n'
```

## Source code

The source code of all packages in the image is available from their original distributors:

- Debian packages: https://sources.debian.org and the Debian archive (`deb-src` entries for "trixie")
- Raspberry Pi packages: https://archive.raspberrypi.com/debian/ (`deb-src` entries for "trixie") and
  https://github.com/raspberrypi
- Linux kernel for the Raspberry Pi: https://github.com/raspberrypi/linux

### Written offer

For devices sold with ShowPlayPI preinstalled: for at least three years after the last distribution of
the device, Robert Skiba will provide – on request, for no more than the cost of physically performing
the distribution – a complete machine-readable copy of the corresponding source code of all software in
the image that is licensed under the GPL, LGPL or a similar license requiring source distribution.
Contact: support@konftools.com

## Container images (future modes)

The planned Ontime and Companion modes will include these programs as container images from their
official publishers (updated at boot when online). They remain under their own licenses:

| Component | License |
|---|---|
| [Ontime](https://github.com/cpvalente/ontime) | GPL-3.0-or-later (covered by the written offer above) |
| [Bitfocus Companion](https://github.com/bitfocus/companion) | MIT (core); device modules under their own, mostly MIT licenses |

ShowPlayPI is not affiliated with or endorsed by the Ontime or Bitfocus Companion projects.
