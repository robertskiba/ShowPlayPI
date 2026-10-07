# ShowPlayPI – development

How the repository is organised, how to test changes on a running Pi and how to build an image.
User documentation: [README](../README.md).

Base: **Raspberry Pi OS Lite 2026-06-18 (Debian 13 trixie, arm64)**.
Plans: [ROADMAP.md](../ROADMAP.md), OSC commands: [OSC.md](OSC.md), changes: [CHANGELOG.md](../CHANGELOG.md).

## Development: push changes to a running Pi

In Git Bash (or WSL) inside the repository:

```bash
./deploy.sh -n 192.168.20.50   # dry run: what would change?
./deploy.sh showplaypi-e84042.local  # overlay to that Pi (device name or IP), restart affected services
./deploy.sh 192.168.20.50      # another Pi
./deploy.sh --boot <target>    # also config.txt, cmdline.txt, README.txt …
./deploy.sh --boot --ini <target>  # … and overwrite showplaypi.ini
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

### Raspberry Pi Imager list

The build also writes `ShowPlayPI-<version>.rpi-imager.json` – an OS list in the format of
[Raspberry Pi Imager](https://github.com/raspberrypi/rpi-imager/tree/main/doc) with sizes, SHA-256
checksums (compressed and uncompressed), the supported devices (Pi 5, Pi 4) and the icon
`imager/showplaypi-icon.svg`. `init_format` is `none`, so the Imager does not offer its OS customisation.
For an existing image: `bash build/imager-json.sh build/out/ShowPlayPI-<version>.img.xz`.

The URLs point to the GitHub release asset `v<version>` and to the icon on the branch `main`; both only
work once the repository is public. Other locations: set `IMAGER_IMAGE_URL` and `IMAGER_ICON_URL`.
**Permanent address of the list:** `rpi-imager.json` in the main folder of the repository, on the branch
`main`:

    https://raw.githubusercontent.com/robertskiba/ShowPlayPI/main/rpi-imager.json

The address never changes; only the content is updated with every release. A release build (image named
`ShowPlayPI-<version>.img.xz`, built from its tag) copies its list there automatically – commit it together
with the release. (GitHub's `releases/latest` address is not used: it skips pre-releases, i.e. all betas.)
The address works once the repository is public. Test it with
`rpi-imager --repo https://raw.githubusercontent.com/robertskiba/ShowPlayPI/main/rpi-imager.json`.

`build/compare.sh old.img new.img` compares two images (packages, units, overlay, boot partition, user).

### Creating an image from a running Pi

Before copying the SD card of a hand-configured Pi, run `showplaypi-rearm` via SSH. It removes host keys,
machine ID, logs, caches, shell history and the browser profile, then shuts the Pi down.

## Repository layout

```
rootfs/        files copied 1:1 into the root file system (overlay on top of the base image)
bootfs/        files for the boot partition /boot/firmware (config.txt, cmdline.txt, showplaypi.ini template)
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
imager/        icon for the Raspberry Pi Imager list
```

## On the device

```
/boot/firmware          partition 1, FAT: firmware, kernel, config.txt, cmdline.txt, showplaypi.ini (copy)
/                       partition 2, ext4: the system (12 GiB after the first start, about 5.9 GiB on 8 GB cards)
/media/showplaypi       partition 3, exFAT "SHOWPLAYPI": showplaypi.ini (copy), configurator, HTML, VIDEO,
                        AUDIO, PRESETS – also the USB drive and the network share
/etc/showplaypi/showplaypi.ini   the active configuration, read by all ShowPlayPI services
```

`showplaypi-media` creates partition 3 on the first start, mounts it, restores missing files and reconciles
the three copies of `showplaypi.ini` (the copy changed since the last start wins). `showplaypi-usb-drive`
hands the partition to a computer connected via USB-C and takes it back afterwards; Samba pauses meanwhile.

## Versions

The first stable release is **1.0.0** (2026-10-07), after the betas `1.0.0-beta.1` to `1.0.0-beta.3`. Versions
follow semantic versioning: fixes as `1.0.x`, new features as `1.x.0`, `2.0.0` for incompatible changes of
`showplaypi.ini`.

The version number lives in `rootfs/etc/showplaypi-release`. Every release gets a Git tag `vX.Y.Z`.

## Not in the repository

Secrets and device-specific data: password hashes, VNC password, SSH host keys, machine ID,
shell history, Chromium profile. They are created during the build or on first boot.

## License

MIT – see [LICENSE](../LICENSE). The image also contains third-party software under its own licenses,
see [THIRD-PARTY.md](../THIRD-PARTY.md). Changes: [CHANGELOG.md](../CHANGELOG.md).

## Support

https://konftools.com · support@konftools.com
