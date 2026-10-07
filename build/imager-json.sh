#!/bin/bash
# Writes the os_list JSON for Raspberry Pi Imager (a "sublist", see
# https://github.com/raspberrypi/rpi-imager/tree/main/doc) for a built image.
# build.sh calls it automatically; it can also be run on its own (WSL, Linux, Git Bash with xz).
#
# Usage: build/imager-json.sh build/out/ShowPlayPI-<version>.img.xz
# Output: next to the image, <image>.rpi-imager.json
#
# Environment variables (where the files are published – must be publicly reachable):
#   IMAGER_IMAGE_URL   download URL of the .img.xz (default: GitHub release asset v<version>)
#   IMAGER_ICON_URL    URL of imager/showplaypi-icon.svg (default: raw file on GitHub, branch main)
set -Eeuo pipefail

REPO=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
XZ=${1:?Usage: $0 <image.img.xz>}
[[ -f $XZ ]] || { echo "Not found: $XZ" >&2; exit 1; }
FILE=$(basename "$XZ")

# shellcheck disable=SC1091
source "$REPO/rootfs/etc/showplaypi-release"
GITHUB=https://github.com/robertskiba/ShowPlayPI
IMAGE_URL=${IMAGER_IMAGE_URL:-$GITHUB/releases/download/v$SHOWPLAYPI_VERSION/$FILE}
ICON_URL=${IMAGER_ICON_URL:-https://raw.githubusercontent.com/robertskiba/ShowPlayPI/main/imager/showplaypi-icon.svg}

echo "Computing checksums for $FILE (decompresses the image once) ..."
DOWNLOAD_SIZE=$(stat -c %s "$XZ")
DOWNLOAD_SHA256=$(sha256sum "$XZ" | cut -d' ' -f1)
EXTRACT_SIZE=$(xz --robot --list "$XZ" | awk '$1 == "totals" { print $5 }')
# The Imager checks the SHA-256 of the *uncompressed* image and refuses to finish writing if it differs
EXTRACT_SHA256=$(xz -dc "$XZ" | sha256sum | cut -d' ' -f1)

# init_format "none": no OS customisation in the Imager – ShowPlayPI brings its own configuration
# (showplaypi.ini), and hostname/user/Wi-Fi settings from the Imager would interfere with it.
# "imager" lists the supported devices (as in Raspberry Pi's own list): needed when the file is opened on its
# own (rpi-imager --repo <address>); as a sublist of the official list only "os_list" is used.
OUT=${XZ%.img.xz}.rpi-imager.json
cat > "$OUT" <<EOF
{
  "imager": {
    "devices": [
      {
        "name": "Raspberry Pi 5",
        "tags": ["pi5-64bit"],
        "icon": "https://downloads.raspberrypi.com/imager/icons/RPi_5.png",
        "description": "Raspberry Pi 5",
        "matching_type": "exclusive"
      },
      {
        "name": "Raspberry Pi 4",
        "tags": ["pi4-64bit"],
        "icon": "https://downloads.raspberrypi.com/imager/icons/RPi_4.png",
        "description": "Raspberry Pi 4 Model B",
        "matching_type": "exclusive"
      }
    ]
  },
  "os_list": [
    {
      "name": "ShowPlayPI",
      "description": "The versatile tool for exhibition and event technology: full-screen browser for interactive and non-interactive screens, video player and audio jingle or loop player. Optionally also a Bitfocus Companion or Ontime host. Easy to set up, no Linux skills required. Version $SHOWPLAYPI_VERSION",
      "icon": "$ICON_URL",
      "url": "$IMAGE_URL",
      "website": "https://konftools.com",
      "release_date": "$SHOWPLAYPI_RELEASE_DATE",
      "extract_size": $EXTRACT_SIZE,
      "extract_sha256": "$EXTRACT_SHA256",
      "image_download_size": $DOWNLOAD_SIZE,
      "image_download_sha256": "$DOWNLOAD_SHA256",
      "devices": [
        "pi5-64bit",
        "pi4-64bit"
      ],
      "init_format": "none",
      "architecture": "armv8"
    }
  ]
}
EOF
echo "Written: $OUT"

# A release image (ShowPlayPI-<version>.img.xz, built from its tag) also updates rpi-imager.json in the main
# folder of the repository: the list the Imager reads at a permanent address, see docs/DEVELOPMENT.md.
# Commit it together with the release.
if [[ $FILE == "ShowPlayPI-$SHOWPLAYPI_VERSION.img.xz" ]]; then
    cp "$OUT" "$REPO/rpi-imager.json"
    echo "Updated: rpi-imager.json (permanent Imager list – commit it with the release)"
fi
