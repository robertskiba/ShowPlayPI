#!/bin/bash
# Runs ON THE PI (as root, started by deploy.sh).
# Installs overlay, boot files and units from the uploaded package and restarts affected services.
#
# Usage: remote-apply.sh <package-dir> [--dry-run] [--no-restart]
set -Eeuo pipefail

PKG=$1; shift
DRY_RUN=""
RESTART=yes
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=--dry-run; RESTART=no ;;
        --no-restart) RESTART=no ;;
    esac
done

S=$PKG/scripts
changes=$(
    # Files that were removed from the repository
    while read -r path; do
        [[ -z "$path" || "$path" == \#* ]] && continue
        [[ -e $path ]] || continue
        echo "REMOVED $path"
        [[ -n $DRY_RUN ]] && continue
        # Units are stopped and disabled before their file disappears
        if [[ $path == /etc/systemd/system/*.service || $path == /etc/systemd/system/*.timer ]]; then
            systemctl disable --now "$(basename "$path")" >/dev/null 2>&1 || true
        fi
        rm -f "$path"
    done < "$PKG/meta/removed-files.txt"

    bash "$S/install-overlay.sh" "$PKG/rootfs" / "$PKG/meta/permissions.txt" $DRY_RUN
    if [[ -d $PKG/bootfs ]]; then
        bash "$S/install-boot.sh" "$PKG/bootfs" /boot/firmware $DRY_RUN
    fi
    bash "$S/apply-services.sh" "$PKG/services.txt" $DRY_RUN
)

if [[ -z $changes ]]; then
    echo "No changes – the Pi already matches the repository."
    exit 0
fi

echo "$changes"
echo

if [[ -n $DRY_RUN ]]; then
    echo "(dry run – nothing was changed)"
    exit 0
fi

# Record the repository revision on the device
{
    echo "SHOWPLAYPI_GIT=$(cat "$PKG/GIT_VERSION")"
    echo "SHOWPLAYPI_DEPLOYED=$(date '+%Y-%m-%d %H:%M:%S')"
} > /etc/showplaypi-build

changed() { grep -qE "$1" <<< "$changes"; }

if changed '/etc/systemd/'; then
    systemctl daemon-reload
fi

if changed '/etc/tmpfiles\.d/'; then
    systemd-tmpfiles --create
fi

if changed '/etc/systemd/journald\.conf\.d/'; then
    systemctl restart systemd-journald
fi

if changed '/etc/samba/'; then
    smbcontrol smbd reload-config 2>/dev/null || true
fi

if changed '/etc/udev/rules\.d/'; then
    udevadm control --reload
    udevadm trigger --subsystem-match=hidraw --subsystem-match=usb
fi

if changed 'splash-screen-hook|/usr/lib/firmware/logo\.tga'; then
    echo "Boot logo changed – regenerating initramfs ..."
    update-initramfs -u -k all >/dev/null
fi

# Which services are affected?
restart=()
changed 'showplaypi-osc'                  && restart+=(showplaypi-osc.service)
changed 'showplaypi-web-watchdog'         && restart+=(showplaypi-web-watchdog.service)
changed 'showplaypi-(browser|display|current-url|kiosk)|\.xinitrc|/home/admin/kiosk/|/etc/X11/' \
                                          && restart+=(showplaypi-kiosk.service showplaypi-vnc.service)
changed 'showplaypi-vnc'                  && restart+=(showplaypi-vnc.service)
changed 'showplaypi-idle'                 && restart+=(showplaypi-idle.service)
changed 'showplaypi-mode'                 && restart+=(showplaypi-mode.service)
changed 'showplaypi-video|showplaypi_mpv' && restart+=(showplaypi-video.service)
changed 'showplaypi-audio|showplaypi_mpv' && restart+=(showplaypi-audio.service)
changed 'showplaypi-companion'            && restart+=(showplaypi-companion.service)
changed 'showplaypi-(ontime|container-image)' && restart+=(showplaypi-ontime.service)
changed 'showplaypi-timezone'             && restart+=(showplaypi-timezone.service)
changed 'showplaypi-upnp'                 && restart+=(showplaypi-upnp.service)
changed 'showplaypi-usb-config-mode'      && restart+=(showplaypi-usb-config-mode.service)
changed 'showplaypi-usb-drive'            && restart+=(showplaypi-usb-drive.service)
changed 'showplaypi-restart.path'        && restart+=(showplaypi-restart.path)
changed 'showplaypi-data-hygiene.timer'   && restart+=(showplaypi-data-hygiene.timer)

reboot_hint=""
changed 'showplaypi-(usb-gadget|system-config|network-config|media)|/boot/firmware/|/etc/sudoers\.d/|/etc/pipewire/|/etc/wireplumber/|/var/lib/systemd/linger/|splash|logo|ENABLED|DISABLED' \
    && reboot_hint=yes

if [[ ${#restart[@]} -gt 0 ]]; then
    mapfile -t restart < <(printf '%s\n' "${restart[@]}" | awk '!seen[$0]++')
    if [[ $RESTART == yes ]]; then
        echo "Restarting: ${restart[*]}"
        systemctl restart "${restart[@]}"
    else
        echo "Restart required for: ${restart[*]}"
    fi
fi

if [[ -n $reboot_hint ]]; then
    echo "Note: these changes only take effect after a reboot:  sudo reboot"
fi
