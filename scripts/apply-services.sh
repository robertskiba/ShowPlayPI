#!/bin/bash
# Enables/disables systemd units according to services.txt. Also works inside a chroot.
#
# Usage:   apply-services.sh <services.txt> [--dry-run]
# Output:  "ENABLED <unit>" or "DISABLED <unit>" per change
set -Eeuo pipefail

LIST=$1
DRY_RUN=${2:-}

# Look directly in the file system – "systemctl cat" does not work inside a chroot
unit_exists() {
    local file=$1
    [[ $file == *@*.* ]] && file=${file%%@*}@.${file##*.}
    for dir in /etc/systemd/system /usr/lib/systemd/system /lib/systemd/system; do
        [[ -e $dir/$file ]] && return 0
    done
    return 1
}

while read -r action unit; do
    [[ -z "$action" || "$action" == \#* ]] && continue

    if ! unit_exists "$unit"; then
        echo "WARNING: unit $unit does not exist – skipped" >&2
        continue
    fi

    state=$(systemctl is-enabled "$unit" 2>/dev/null || true)
    case $action in
        enable)
            [[ $state == enabled ]] && continue
            echo "ENABLED $unit"
            [[ -n $DRY_RUN ]] || systemctl enable "$unit" 2>/dev/null
            ;;
        disable)
            [[ $state == enabled ]] || continue
            echo "DISABLED $unit"
            [[ -n $DRY_RUN ]] || systemctl disable "$unit" 2>/dev/null
            ;;
        *)
            echo "WARNING: unknown action '$action' in $LIST" >&2
            ;;
    esac
done < "$LIST"
