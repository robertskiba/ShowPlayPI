#!/bin/bash
# Runs INSIDE THE CHROOT of the image (ARM64 via qemu), started by build.sh.
#
#   chroot-setup.sh packages   upgrade/install packages, create user admin
#   chroot-setup.sh finalize   units, VNC password, directories, initramfs (after the overlay)
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C.UTF-8
cd /tmp/showplaypi-build
# shellcheck disable=SC1091
source ./config.env

apt_opts=(-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)

case ${1:-} in
packages)
    apt-get update
    if [[ $FULL_UPGRADE == yes ]]; then
        apt-get "${apt_opts[@]}" full-upgrade
    fi

    mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' packages.txt)
    # Without "recommended" packages – otherwise ~90 unneeded packages are added
    # (Perl libraries, a terminal, Vulkan …). If something is missing, add it to packages.txt.
    apt-get "${apt_opts[@]}" --no-install-recommends install "${packages[@]}"
    # Remove old kernels of the base image and orphaned dependencies
    apt-get -y autoremove --purge

    # The base image has a placeholder user "pi" (UID 1000). Raspberry Pi OS renames it on first boot
    # via userconf – we do it now, so the setup wizard is skipped.
    if ! id admin >/dev/null 2>&1; then
        /usr/lib/userconf-pi/userconf admin
    fi
    echo "admin:$ADMIN_PASSWORD" | chpasswd

    # Groups for hardware access (GPIO, I2C, SPI, video, audio, input, network)
    for g in adm dialout cdrom sudo audio video plugdev games users input render netdev spi i2c gpio; do
        if getent group "$g" >/dev/null; then
            usermod -aG "$g" admin
        fi
    done

    ln -sf "../usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    echo "$TIMEZONE" > /etc/timezone
    ;;

finalize)
    bash scripts/apply-services.sh services.txt
    systemctl set-default multi-user.target

    install -d -o admin -g admin -m 775 /home/admin/.config
    install -d -o admin -g admin -m 700 /home/admin/.config/chromium-kiosk
    install -d -o admin -g admin -m 775 /home/admin/.vnc
    x11vnc -storepasswd "$VNC_PASSWORD" /home/admin/.vnc/passwd >/dev/null
    chown admin:admin /home/admin/.vnc/passwd
    chmod 600 /home/admin/.vnc/passwd

    # Persistent journal (see journald.conf.d/persistent.conf)
    install -d /var/log/journal

    # The boot logo lives in the initramfs (splash-screen-hook.sh + /usr/lib/firmware/logo.tga)
    update-initramfs -u -k all
    ;;

*)
    echo "Usage: $0 packages|finalize" >&2
    exit 2
    ;;
esac
