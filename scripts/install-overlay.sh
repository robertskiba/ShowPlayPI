#!/bin/bash
# Installs the rootfs overlay into a target system using the permissions from meta/permissions.txt.
# Used by build/build.sh (target: mounted image) and deploy.sh (target: / on the Pi).
#
# Usage:   install-overlay.sh <overlay-dir> <target-root> <permissions.txt> [--dry-run]
# Output:  one line per change: "NEW <path>", "CHANGED <path>" or "PERMS <path>"
set -Eeuo pipefail

SRC=${1%/}
DEST=${2%/}
PERMS=$3
DRY_RUN=${4:-}

declare -A MODE OWNER GROUP
while read -r mode owner group path; do
    [[ -z "$mode" || "$mode" == \#* ]] && continue
    MODE[$path]=$mode
    OWNER[$path]=$owner
    GROUP[$path]=$group
done < "$PERMS"

# Resolve users/groups in the target system, not on the host (WSL has no "admin" user)
lookup_id() {
    awk -F: -v name="$2" '$1 == name { print $3; found = 1 } END { exit !found }' "$DEST/etc/$1" ||
        { echo "ERROR: '$2' is missing in $DEST/etc/$1" >&2; exit 1; }
}

# Prints "mode owner group"; "- - -" for directories without an entry
perm_for() {
    local path=$1 kind=$2
    if [[ -n "${MODE[$path]:-}" ]]; then
        echo "${MODE[$path]} ${OWNER[$path]} ${GROUP[$path]}"
    elif [[ $kind == d ]]; then
        echo "- - -"
    else
        echo "WARNING: no entry in permissions.txt for $path" >&2
        case $path in
            /usr/local/bin/*|/usr/local/sbin/*) echo "755 root root" ;;
            *) echo "644 root root" ;;
        esac
    fi
}

# Directories first (parents before children)
while IFS= read -r -d '' dir; do
    rel=${dir#"$SRC"}
    target=$DEST$rel
    read -r mode owner group < <(perm_for "$rel/" d)

    if [[ ! -d $target ]]; then
        [[ $mode == - ]] && { mode=755; owner=root; group=root; }
        echo "NEW $rel/"
    elif [[ $mode == - ]]; then
        continue
    else
        uid=$(lookup_id passwd "$owner"); gid=$(lookup_id group "$group")
        [[ "$(stat -c '%a %u %g' "$target")" == "$mode $uid $gid" ]] && continue
        echo "PERMS $rel/"
    fi

    [[ -n $DRY_RUN ]] && continue
    uid=$(lookup_id passwd "$owner"); gid=$(lookup_id group "$group")
    install -d -m "$mode" -o "$uid" -g "$gid" "$target"
done < <(find "$SRC" -mindepth 1 -type d -print0 | sort -z)

# Files
while IFS= read -r -d '' file; do
    rel=${file#"$SRC"}
    target=$DEST$rel
    read -r mode owner group < <(perm_for "$rel" f)
    uid=$(lookup_id passwd "$owner"); gid=$(lookup_id group "$group")

    if [[ ! -e $target ]]; then
        echo "NEW $rel"
    elif ! cmp -s "$file" "$target"; then
        echo "CHANGED $rel"
    elif [[ "$(stat -c '%a %u %g' "$target")" != "$mode $uid $gid" ]]; then
        echo "PERMS $rel"
    else
        continue
    fi

    [[ -n $DRY_RUN ]] && continue
    install -m "$mode" -o "$uid" -g "$gid" "$file" "$target"
done < <(find "$SRC" -type f -print0 | sort -z)
