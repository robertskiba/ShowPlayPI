#!/bin/bash
# Builds a ShowPlayPI image from the official Raspberry Pi OS Lite and this repository.
# Runs as root under WSL2 (Ubuntu) or Linux. On Windows simply use build.cmd.
#
# Output: build/out/ShowPlayPI-<version>[-<git>].img.xz (+ .sha256, .packages.txt, .rpi-imager.json)
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
# The template of showplaypi.ini is also the delivery state used by the factory reset
install -D -m 644 "$REPO/bootfs/showplaypi.ini" "$SRC/rootfs/usr/share/showplaypi/showplaypi.ini.default"

# --- Tools -------------------------------------------------------------------
missing=()
for tool in curl xz parted losetup resize2fs e2fsck zerofree skopeo; do
    command -v "$tool" >/dev/null || missing+=("$tool")
done
[[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]] || missing+=(qemu-aarch64)
if [[ ${#missing[@]} -gt 0 ]]; then
    log "Installing missing tools: ${missing[*]}"
    apt-get update -qq
    apt-get install -y -qq curl xz-utils parted e2fsprogs util-linux zerofree skopeo
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

# Companion (native) and Ontime (container image) for the Companion and Ontime modes – cached like the base image
COMPANION_PACKAGE=$CACHE/$(basename "$COMPANION_URL")
if [[ ! -f $COMPANION_PACKAGE ]]; then
    log "Downloading Companion $(basename "$COMPANION_PACKAGE")"
    curl -fL --progress-bar -o "$COMPANION_PACKAGE.part" "$COMPANION_URL"
    mv "$COMPANION_PACKAGE.part" "$COMPANION_PACKAGE"
fi
echo "$COMPANION_SHA256  $COMPANION_PACKAGE" | sha256sum -c --quiet \
    || die "Companion checksum mismatch – delete $COMPANION_PACKAGE and start again"

COMPANION_BUNDLE=$CACHE/$(basename "$COMPANION_BUNDLE_URL")
if [[ ! -f $COMPANION_BUNDLE ]]; then
    log "Downloading the Companion offline module bundle $(basename "$COMPANION_BUNDLE")"
    curl -fL --progress-bar -o "$COMPANION_BUNDLE.part" "$COMPANION_BUNDLE_URL"
    mv "$COMPANION_BUNDLE.part" "$COMPANION_BUNDLE"
fi
echo "$COMPANION_BUNDLE_SHA256  $COMPANION_BUNDLE" | sha256sum -c --quiet \
    || die "Module bundle checksum mismatch – delete $COMPANION_BUNDLE and start again"

ONTIME_CACHE=$CACHE/ontime-$(basename "${ONTIME_IMAGE##*:}").tar
if [[ ! -f $ONTIME_CACHE ]]; then
    log "Downloading Ontime container image $ONTIME_IMAGE (ARM64)"
    rm -f "$ONTIME_CACHE.part"
    skopeo --override-os linux --override-arch arm64 copy --quiet \
        "docker://$ONTIME_IMAGE" "docker-archive:$ONTIME_CACHE.part:$ONTIME_IMAGE_TAG"
    mv "$ONTIME_CACHE.part" "$ONTIME_CACHE"
fi

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
log "Installing Companion and the Ontime container image"
rm -rf "$ROOT/opt/companion"
mkdir -p "$ROOT/opt/companion"
tar -xzf "$COMPANION_PACKAGE" -C "$ROOT/opt/companion" --strip-components=1 --no-same-owner
install -D -m 644 "$COMPANION_BUNDLE" "$ROOT/usr/share/showplaypi/companion/companion-offline-module-bundle.tar.gz"
install -D -m 644 "$ONTIME_CACHE" "$ROOT/usr/share/showplaypi/containers/$ONTIME_ARCHIVE"
# A freshly flashed card should only show the user files, even before the first start
python3 "$SRC/rootfs/usr/local/sbin/showplaypi-hide-boot-files" "$ROOT/boot/firmware" | sed 's/^/    /'

cat > "$ROOT/etc/showplaypi-build" <<EOF
SHOWPLAYPI_GIT=$GITREV
SHOWPLAYPI_BUILT=$(date '+%Y-%m-%d %H:%M:%S')
SHOWPLAYPI_BASE=$(basename "$BASE_IMAGE_URL")
EOF
# systemd sets the clock to this file's date at the very beginning of the first start: the clock never starts
# before the build, so the first log entries are not dated months too early
mkdir -p "$ROOT/var/lib/systemd/timesync"
touch "$ROOT/var/lib/systemd/timesync/clock"

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
# Right after unmounting, udev may still hold the partition for a moment ("in use") – retry briefly
for attempt in 1 2 3 4 5; do
    fsck_status=0
    fsck_output=$(e2fsck -fy "${LOOP}p2" 2>&1) || fsck_status=$?
    (( fsck_status <= 1 )) && break
    if (( attempt == 5 )); then
        printf '%s\n' "$fsck_output" >&2
        die "e2fsck after the build failed"
    fi
    udevadm settle 2>/dev/null || true
    sleep 3
done
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

log "Writing the Raspberry Pi Imager list"
bash "$REPO/build/imager-json.sh" "$OUT/$NAME.img.xz" | sed 's/^/    /'

log "Done: build/out/$NAME.img.xz"
cat "$OUT/$NAME.img.xz.sha256"
