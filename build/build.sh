#!/bin/bash
# Builds a ShowPlayPI image from the official Raspberry Pi OS Lite and this repository.
# Runs as root under WSL2 (Ubuntu) or Linux. On Windows simply use build.cmd.
#
# Output: build/out/ShowPlayPI-<version>[-<git>].img.xz (+ .sha256)
#
# Environment variables:
#   SHOWPLAYPI_WORK=/path   working directory (default /var/tmp/showplaypi-build, needs ~10 GB)
#   KEEP_IMG=1              keep the uncompressed .img in the working directory
set -Eeuo pipefail

REPO=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
# shellcheck disable=SC1091
source "$REPO/build/config.env"

WORK=${SHOWPLAYPI_WORK:-/var/tmp/showplaypi-build}
CACHE=$WORK/cache
ROOT=$WORK/root
OUT=$REPO/build/out

log() { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "build.sh must run as root (WSL: wsl -u root ...)"

# --- Version and name --------------------------------------------------------
VERSION=$(. "$REPO/rootfs/etc/showplaypi-release"; echo "$SHOWPLAYPI_VERSION")
GITREV=$(git -c safe.directory='*' -C "$REPO" describe --tags --always --dirty 2>/dev/null || echo unknown)
NAME=ShowPlayPI-$VERSION
[[ $GITREV == "v$VERSION" ]] || NAME=$NAME-$GITREV
IMG=$WORK/$NAME.img

log "Building $NAME (Git: $GITREV)"

# Work on a snapshot: the build takes a long time and must match the revision it is named after,
# even if files in the repository are edited meanwhile.
SRC=$WORK/src
rm -rf "$SRC"
mkdir -p "$SRC/build"
cp -r "$REPO/rootfs" "$REPO/bootfs" "$REPO/meta" "$REPO/scripts" \
      "$REPO/packages.txt" "$REPO/services.txt" "$SRC/"
cp "$REPO/build/config.env" "$REPO/build/chroot-setup.sh" "$SRC/build/"

# --- Tools -------------------------------------------------------------------
missing=()
for tool in curl xz parted losetup resize2fs e2fsck zerofree; do
    command -v "$tool" >/dev/null || missing+=("$tool")
done
[[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]] || missing+=(qemu-aarch64)
if [[ ${#missing[@]} -gt 0 ]]; then
    log "Installing missing tools: ${missing[*]}"
    apt-get update -qq
    apt-get install -y -qq curl xz-utils parted e2fsprogs util-linux zerofree
    # Since Ubuntu 26.04 the static ARM64 emulation is called qemu-user + qemu-user-binfmt
    if apt-cache show qemu-user-binfmt >/dev/null 2>&1; then
        apt-get install -y -qq qemu-user qemu-user-binfmt
    else
        apt-get install -y -qq qemu-user-static binfmt-support
    fi
fi

if [[ ! -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]]; then
    systemctl restart systemd-binfmt 2>/dev/null || update-binfmts --enable qemu-aarch64 2>/dev/null || true
fi
[[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]] || die "ARM64 emulation (binfmt qemu-aarch64) is not active"

# --- Clean up on abort -------------------------------------------------------
LOOP=""
cleanup() {
    set +e
    if mountpoint -q "$ROOT"; then
        umount -R "$ROOT" 2>/dev/null || umount -Rl "$ROOT"
    fi
    [[ -n $LOOP ]] && losetup -d "$LOOP" 2>/dev/null
}
trap cleanup EXIT

mkdir -p "$CACHE" "$ROOT" "$OUT"

# --- 1. Fetch the base image -------------------------------------------------
BASE=$CACHE/$(basename "$BASE_IMAGE_URL")
if [[ ! -f $BASE ]]; then
    log "Downloading base image $(basename "$BASE")"
    curl -fL --progress-bar -o "$BASE.part" "$BASE_IMAGE_URL"
    mv "$BASE.part" "$BASE"
fi
log "Verifying base image checksum"
echo "$BASE_IMAGE_SHA256  $BASE" | sha256sum -c --quiet || die "Checksum mismatch – delete $BASE and start again"

# --- 2. Decompress and enlarge -----------------------------------------------
log "Decompressing and enlarging by $EXTRA_SIZE_MB MB"
xz -dc "$BASE" > "$IMG"
truncate -s "+${EXTRA_SIZE_MB}M" "$IMG"
parted -s "$IMG" resizepart 2 100%

LOOP=$(losetup -fP --show "$IMG")
e2fsck -fy "${LOOP}p2" >/dev/null || [[ $? -le 1 ]] || die "e2fsck failed"
resize2fs "${LOOP}p2" >/dev/null

# --- 3. Mount and prepare the chroot -----------------------------------------
log "Mounting image"
mount "${LOOP}p2" "$ROOT"
mount "${LOOP}p1" "$ROOT/boot/firmware"
for fs in dev dev/pts proc sys; do
    mount --bind "/$fs" "$ROOT/$fs"
done

# Network inside the chroot, do not start services
mv "$ROOT/etc/resolv.conf" "$ROOT/etc/resolv.conf.showplaypi-build" 2>/dev/null || true
cp -L /etc/resolv.conf "$ROOT/etc/resolv.conf"
printf '#!/bin/sh\nexit 101\n' > "$ROOT/usr/sbin/policy-rc.d"
chmod 755 "$ROOT/usr/sbin/policy-rc.d"

STAGE=$ROOT/tmp/showplaypi-build
mkdir -p "$STAGE"
cp -r "$SRC/scripts" "$SRC/packages.txt" "$SRC/services.txt" \
      "$SRC/build/config.env" "$SRC/build/chroot-setup.sh" "$STAGE/"

# --- 4. Packages and user ----------------------------------------------------
log "Installing packages (this takes a while under emulation)"
chroot "$ROOT" /bin/bash /tmp/showplaypi-build/chroot-setup.sh packages

# --- 5. Overlay and boot partition -------------------------------------------
log "Installing ShowPlayPI files"
bash "$SRC/scripts/install-overlay.sh" "$SRC/rootfs" "$ROOT" "$SRC/meta/permissions.txt" | sed 's/^/    /'
bash "$SRC/scripts/install-boot.sh" "$SRC/bootfs" "$ROOT/boot/firmware" | sed 's/^/    /'

cat > "$ROOT/etc/showplaypi-build" <<EOF
SHOWPLAYPI_GIT=$GITREV
SHOWPLAYPI_BUILT=$(date '+%Y-%m-%d %H:%M:%S')
SHOWPLAYPI_BASE=$(basename "$BASE_IMAGE_URL")
EOF

# --- 6. Services, VNC, initramfs ---------------------------------------------
log "Setting up services"
chroot "$ROOT" /bin/bash /tmp/showplaypi-build/chroot-setup.sh finalize

# Package manifest next to the image: documents exactly which third-party versions this release
# contains (see THIRD-PARTY.md)
chroot "$ROOT" dpkg-query -W -f='${Package}\t${Version}\n' > "$OUT/$NAME.packages.txt"

# --- 7. Clean up (same as showplaypi-rearm) ----------------------------------
log "Cleaning up"
chroot "$ROOT" apt-get clean
rm -rf "$ROOT"/var/lib/apt/lists/* "$STAGE" "$ROOT/usr/sbin/policy-rc.d"
rm -f "$ROOT"/etc/ssh/ssh_host_* "$ROOT/var/lib/systemd/random-seed" "$ROOT/root/.bash_history"
rm -f "$ROOT/etc/resolv.conf"
mv "$ROOT/etc/resolv.conf.showplaypi-build" "$ROOT/etc/resolv.conf" 2>/dev/null || true
# Empty machine-id = "first boot": the file system grows and SSH host keys are generated
: > "$ROOT/etc/machine-id"
if [[ -e $ROOT/var/lib/dbus/machine-id && ! -L $ROOT/var/lib/dbus/machine-id ]]; then
    : > "$ROOT/var/lib/dbus/machine-id"
fi
find "$ROOT/var/log" -type f -exec truncate -s 0 {} +
rm -rf "${ROOT:?}"/tmp/* "${ROOT:?}"/var/tmp/*

umount -R "$ROOT"
e2fsck -fy "${LOOP}p2" >/dev/null || [[ $? -le 1 ]] || die "e2fsck after the build failed"
# Fill free space with zeros: deleted package files would otherwise compress badly
log "Zeroing free space (smaller download)"
zerofree "${LOOP}p2"
losetup -d "$LOOP"
LOOP=""

# --- 8. Compress -------------------------------------------------------------
log "Compressing to build/out/$NAME.img.xz"
xz -T0 -6 -c "$IMG" > "$OUT/$NAME.img.xz"
(cd "$OUT" && sha256sum "$NAME.img.xz" > "$NAME.img.xz.sha256")
[[ -n ${KEEP_IMG:-} ]] || rm -f "$IMG"

log "Done: build/out/$NAME.img.xz"
cat "$OUT/$NAME.img.xz.sha256"
