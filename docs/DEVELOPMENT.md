# ShowPlayPI – development

How the repository is organised, how to test changes on a running Pi and how to build an image.
User documentation: [README](../README.md).

Base: **Raspberry Pi OS Lite 2026-06-18 (Debian 13 trixie, arm64)**.
Plans: [ROADMAP.md](../ROADMAP.md), OSC commands: [OSC.md](OSC.md), changes: [CHANGELOG.md](../CHANGELOG.md).

## Development: push changes to a running Pi

In Git Bash (or WSL) inside the repository:

```bash
./deploy.sh -n                 # dry run: what would change?
./deploy.sh                    # overlay to admin@showplaypi.local, restart affected services
./deploy.sh 192.168.20.50      # another Pi
./deploy.sh --boot             # also config.txt, cmdline.txt, content/ …
./deploy.sh --boot --ini       # … and overwrite showplaypi.ini
```

There is a single password prompt (`admin`). The script lists every changed file, restarts the affected
services and tells you when a `sudo reboot` is required. Afterwards `/etc/showplaypi-build` on the Pi
records which Git revision is installed.

Workflow: change in the repo → `./deploy.sh` → test → `git commit`.

## Release: build an image

Double-click `build.cmd` (or in WSL: `sudo bash build/build.sh`).

1. downloads the official Raspberry Pi OS Lite (version and checksum in `build/config.env`, cached)
2. installs `packages.txt` in an ARM64 chroot (qemu) and creates the user `admin`
3. installs `rootfs/` and `bootfs/`, enables the units from `services.txt`
4. cleans up like `showplaypi-rearm` and writes `build/out/ShowPlayPI-<version>.img.xz`

For a release: bump the version in `rootfs/etc/showplaypi-release`, commit, `git tag vX.Y.Z`, then build.
Without a matching tag the file name contains the Git revision
(e.g. `ShowPlayPI-1.0.0-beta.2-v1.0.0-beta.1-3-g1a2b3c4-dirty.img.xz` – 3 commits after the tag, with
uncommitted changes).

`build/compare.sh old.img new.img` compares two images (packages, units, overlay, boot partition, user).

### Creating an image from a running Pi

Before copying the SD card of a hand-configured Pi, run `showplaypi-rearm` via SSH. It removes host keys,
machine ID, logs, caches, shell history and the browser profile, then shuts the Pi down.

## Repository layout

```
rootfs/        files copied 1:1 into the root file system (overlay on top of the base image)
bootfs/        files for the boot partition /boot/firmware (config.txt, cmdline.txt, showplaypi.ini, content/)
packages.txt   additionally installed packages
services.txt   systemd units to enable/disable
deploy.sh      push the overlay to a running Pi over SSH
build.cmd      start the image build on Windows (runs build/build.sh in WSL)
build/         build scripts and config.env (base image, passwords, time zone)
scripts/       shared helpers for build and deploy
meta/
  permissions.txt   mode/owner of every overlay file – add new files here!
  removed-files.txt files that deploy.sh deletes from a running Pi after they were dropped from rootfs/
configurator/  Windows configurator (AutoIt source + icon). build-configurator.cmd compiles the EXE
               into rootfs/usr/share/showplaypi/usb/ – from there it is copied onto the USB drive.
docs/          documentation
```

## Versions

ShowPlayPI has not been released yet. The first public release will be **1.0.0**; until then there are
betas (`1.0.0-beta.1`, `1.0.0-beta.2`, …), tagged `v1.0.0-beta.N`.

The version number lives in `rootfs/etc/showplaypi-release`. Every release gets a Git tag `vX.Y.Z`.

## Not in the repository

Secrets and device-specific data: password hashes, VNC password, SSH host keys, machine ID,
shell history, Chromium profile. They are created during the build or on first boot.

## License

MIT – see [LICENSE](../LICENSE). The image also contains third-party software under its own licenses,
see [THIRD-PARTY.md](../THIRD-PARTY.md). Changes: [CHANGELOG.md](../CHANGELOG.md).

## Support

https://konftools.com · support@konftools.com
