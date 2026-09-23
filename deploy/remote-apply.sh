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
        [[ -n $DRY_RUN ]] || rm -f "$path"
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

if changed 'splash-screen-hook|/usr/lib/firmware/logo\.tga'; then
    echo "Boot logo changed – regenerating initramfs ..."
    update-initramfs -u -k all >/dev/null
fi

# Which services are affected?
restart=()
changed 'showplaypi-osc'                  && restart+=(showplaypi-osc.service)
changed 'showplaypi-web-watchdog'         && restart+=(showplaypi-web-watchdog.service)
changed 'showplaypi-(browser|display|current-url|kiosk)|\.xinitrc|/home/admin/kiosk/' \
                                          && restart+=(showplaypi-kiosk.service showplaypi-vnc.service)
changed 'showplaypi-vnc'                  && restart+=(showplaypi-vnc.service)
changed 'showplaypi-idle'                 && restart+=(showplaypi-idle.service)

reboot_hint=""
changed 'showplaypi-(usb-gadget|system-config|network-config)|/boot/firmware/|/etc/sudoers\.d/|splash|logo|ENABLED|DISABLED' \
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
