#!/bin/bash
# Copies bootfs/ onto the boot partition (FAT, so no permissions/owners).
# cmdline.txt is handled by set-cmdline.sh (keeps root=PARTUUID).
#
# Usage:   install-boot.sh <bootfs-dir> <target, e.g. /boot/firmware> [--dry-run]
# Output:  "NEW <path>" or "CHANGED <path>" per file
set -Eeuo pipefail

SRC=${1%/}
DEST=${2%/}
DRY_RUN=${3:-}
HERE=$(dirname "$(readlink -f "$0")")

while IFS= read -r -d '' file; do
    rel=${file#"$SRC"}
    target=$DEST$rel

    if [[ $rel == /cmdline.txt ]]; then
        bash "$HERE/set-cmdline.sh" "$file" "$target" $DRY_RUN
        continue
    fi

    if [[ ! -e $target ]]; then
        echo "NEW /boot/firmware$rel"
    elif ! cmp -s "$file" "$target"; then
        echo "CHANGED /boot/firmware$rel"
    else
        continue
    fi

    [[ -n $DRY_RUN ]] && continue
    mkdir -p "$(dirname "$target")"
    cp "$file" "$target"
done < <(find "$SRC" -type f -print0 | sort -z)
