#!/bin/bash
# Writes bootfs/cmdline.txt to the target but keeps the device-specific root= argument (PARTUUID)
# of the existing cmdline.txt. Without this the Pi would no longer boot.
#
# Usage:  set-cmdline.sh <new-cmdline.txt> <target-cmdline.txt> [--dry-run]
# Output: "CHANGED /boot/firmware/cmdline.txt" if something changes
set -Eeuo pipefail

NEW=$1
TARGET=$2
DRY_RUN=${3:-}

root_arg=$(grep -oE 'root=[^ ]+' "$TARGET") ||
    { echo "ERROR: no root= argument in $TARGET" >&2; exit 1; }

result=$(sed -E "s#root=[^ ]+#${root_arg}#" "$NEW" | tr -d '\r')

if [[ "$result" != "$(cat "$TARGET")" ]]; then
    echo "CHANGED /boot/firmware/cmdline.txt"
    [[ -n $DRY_RUN ]] || printf '%s\n' "$result" > "$TARGET"
fi
