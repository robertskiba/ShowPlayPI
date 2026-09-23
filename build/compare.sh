#!/bin/bash
# Compares two ShowPlayPI images (uncompressed .img): packages, enabled units, overlay files,
# boot partition and user. Runs as root under WSL/Linux.
#
# Usage: compare.sh <old.img> <new.img>
set -Eeuo pipefail

A_IMG=$1
B_IMG=$2
REPO=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
TMP=$(mktemp -d)
LOOPS=()

cleanup() {
    set +e
    umount -R "$TMP/a" "$TMP/b" 2>/dev/null
    for l in "${LOOPS[@]}"; do losetup -d "$l"; done
    rm -rf "$TMP"
}
trap cleanup EXIT

attach() { # image mountpoint
    local loop
    loop=$(losetup -rfP --show "$1")
    LOOPS+=("$loop")
    mkdir -p "$2"
    mount -o ro "${loop}p2" "$2"
    mount -o ro "${loop}p1" "$2/boot/firmware"
}
attach "$A_IMG" "$TMP/a"
attach "$B_IMG" "$TMP/b"

section() { printf '\n=== %s ===\n' "$*"; }

packages() { awk '/^Package:/{p=$2} /^Status:/{s=$4} /^$/{if(s=="installed")print p}' "$1/var/lib/dpkg/status" | sort; }
section "Packages only in OLD"
comm -23 <(packages "$TMP/a") <(packages "$TMP/b") | tr '\n' ' '; echo
section "Packages only in NEW"
comm -13 <(packages "$TMP/a") <(packages "$TMP/b") | tr '\n' ' '; echo

units() { (cd "$1/etc/systemd/system" && find . -path '*.wants/*' | sed 's|^\./||' | sort); }
section "Enabled units (< only OLD, > only NEW)"
diff <(units "$TMP/a") <(units "$TMP/b") | grep '^[<>]' || echo "identical"

section "Overlay: differences between NEW and the repository"
bash "$REPO/scripts/install-overlay.sh" "$REPO/rootfs" "$TMP/b" "$REPO/meta/permissions.txt" --dry-run || true
bash "$REPO/scripts/install-boot.sh" "$REPO/bootfs" "$TMP/b/boot/firmware" --dry-run || true
echo "(no output = identical)"

section "Boot partition (file list)"
diff <(cd "$TMP/a/boot/firmware" && find . -type f | sort) \
     <(cd "$TMP/b/boot/firmware" && find . -type f | sort) | grep '^[<>]' || echo "identical"

section "cmdline.txt"
echo "OLD: $(cat "$TMP/a/boot/firmware/cmdline.txt")"
echo "NEW: $(cat "$TMP/b/boot/firmware/cmdline.txt")"

section "User admin"
grep '^admin:' "$TMP/a/etc/passwd" "$TMP/b/etc/passwd" | sed "s|$TMP/||"
for side in a b; do
    printf '%s: ' "$side"
    grep -E '(:|,)admin(,|$)' "$TMP/$side/etc/group" | cut -d: -f1 | tr '\n' ' '; echo
done

section "Other important files"
for f in /home/admin/.vnc/passwd /home/admin/.config/chromium-kiosk /etc/localtime /etc/machine-id /etc/showplaypi-build; do
    for side in a b; do
        if [[ -e $TMP/$side$f || -L $TMP/$side$f ]]; then
            printf '%s %-40s %s\n' "$side" "$f" "$(stat -c '%A %U:%G %s' "$TMP/$side$f")"
        else
            printf '%s %-40s MISSING\n' "$side" "$f"
        fi
    done
done
